// madang.swift — 마당(madang) 팀 데스크톱 펫 (REGISTRY E-17 L1+L2, v0 2026-09-02 · 마스코트 v1 2026-09-03)
//
// 화면 위에 떠 있는 작은 창에 워커(번뜩·몽글·슥슥)를 띄우고,
// `.claude/team/` 파일 신호만 읽어 상태를 말풍선으로 보여준다. 읽기 전용 — 팀 파일을 절대 쓰지 않는다.
//
// 상태 판정은 teamleader/reference/confirm-protocol.md 의 Monitor 스크립트와 같은 규칙:
//   request 있음 + reply 없거나 오래됨 → 컨펌 대기 / 막힘(BLOCKED) / 논의(DISCUSS)
//   request 있음 + reply 더 새로움      → 답장 처리중
//   보고가 브리프보다 오래됨            → 브리프 대기 (미기동 = 유휴 아님)
//   보고·세션 기록 모두 25분 이상 정지 → 유휴 의심 (세션 기록 = ~/.claude/projects/…/*.jsonl mtime, 2026-09-03)
//   그 외                               → 작업중
//   브리프 파일 없음                    → 휴식
//
// 빌드: ./build.sh   실행: madang <프로젝트>/.claude/team   (인자 없으면 $PWD/.claude/team)
// 조작: 드래그로 이동 · 더블클릭 = request/보고 파일 열기 · 메뉴바 👾 = 위치 초기화/종료
// 환경: MADANG_SILENT=1 이면 컨펌·막힘 전환 시 효과음 없음

import AppKit
import Foundation

// MARK: - 설정

let idleMinutes = 25          // Monitor 스크립트와 동일
let pollSeconds = 3.0
let petW: CGFloat = 96, petH: CGFloat = 132

// 스킨 표(claude/roster.json)가 이름·이모지·그림의 단일 원천. key = 파일 신호 경로 식별자(briefs/{key}.md).
struct Role { let id: String; let key: String; let name: String; let emoji: String; let color: NSColor; let aliases: [String] }
let repoClaudeDir = Bundle.main.executableURL!.resolvingSymlinksInPath()
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()   // tools/madang/madang → claude/
let mascotDir = repoClaudeDir.appendingPathComponent("assets/mascots")
let roles: [Role] = {
    let url = repoClaudeDir.appendingPathComponent("roster.json")
    guard let data = try? Data(contentsOf: url),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let list = json["roster"] as? [[String: Any]] else {
        FileHandle.standardError.write("madang: roster.json 을 못 읽음: \(url.path)\n".data(using: .utf8)!)
        return [Role(id: "solver", key: "solver", name: "번뜩", emoji: "🔺", color: hex("#B8563F"), aliases: ["번뜩"]),
                Role(id: "builder", key: "builder", name: "몽글", emoji: "☁️", color: hex("#7A6FA8"), aliases: ["몽글"]),
                Role(id: "sketcher", key: "sketcher", name: "슥슥", emoji: "🟦", color: hex("#3E8E8A"), aliases: ["슥슥"])]
    }
    return list.compactMap { r in
        guard (r["pet"] as? Bool) == true, let id = r["id"] as? String, let key = r["key"] as? String,
              let name = r["name"] as? String, let emoji = r["emoji"] as? String else { return nil }
        return Role(id: id, key: key, name: name, emoji: emoji, color: hex(r["color"] as? String ?? "#1E2430"), aliases: (r["aliases"] as? [String]) ?? [])
    }
}()
func hex(_ h: String) -> NSColor {
    var v: UInt64 = 0; Scanner(string: String(h.dropFirst())).scanHexInt64(&v)
    return NSColor(red: CGFloat((v >> 16) & 0xff) / 255, green: CGFloat((v >> 8) & 0xff) / 255, blue: CGFloat(v & 0xff) / 255, alpha: 1)
}
// 잔잔 팔레트 — 시스템 외양(다크/라이트)에 따라 잉크·종이가 뒤집힌다. 그림도 @dark 변형을 고른다.
// 마스코트 잉크: 메뉴에서 흰색/검정/자동(시스템 외양) 선택. 기본 흰색 — 바탕화면은 대개 사진이라 밝은 실루엣이 잘 보인다.
func inkMode() -> String { UserDefaults.standard.string(forKey: "madang.ink") ?? "white" }
func isDark() -> Bool {
    switch inkMode() {
    case "white": return true
    case "black": return false
    default: return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}
struct Palette { let ink: NSColor; let paper: NSColor; let muted: NSColor
    static var current: Palette { isDark()
        ? Palette(ink: hex("#E6E9EE"), paper: hex("#15181D"), muted: hex("#9AA3AE"))
        : Palette(ink: hex("#1E2430"), paper: hex("#F5F7F8"), muted: hex("#66707E")) }
}
let waitingColor = hex("#D9A21B"), blockedColor = hex("#C0392B")

// MARK: - 팀 디렉토리

func resolveTeamDir() -> URL {
    let a = CommandLine.arguments
    if a.count > 1 {
        return URL(fileURLWithPath: (a[1] as NSString).expandingTildeInPath).standardizedFileURL
    }
    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".claude/team")
}
let teamDir = resolveTeamDir()
if !FileManager.default.fileExists(atPath: teamDir.appendingPathComponent("briefs").path) {
    FileHandle.standardError.write("madang: briefs/ 가 없다: \(teamDir.path)\n사용법: madang <프로젝트>/.claude/team\n".data(using: .utf8)!)
    exit(1)
}

func mtime(_ url: URL) -> Date? {
    (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
}
func firstLine(_ url: URL) -> String {
    guard let h = try? FileHandle(forReadingFrom: url) else { return "" }
    defer { try? h.close() }
    let data = h.readData(ofLength: 4096)
    let text = String(decoding: data, as: UTF8.self)
    let line = text.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? ""
    return line.replacingOccurrences(of: "**", with: "")
               .replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
               .trimmingCharacters(in: .whitespaces)
}

// MARK: - 상태

enum PetState: Equatable {
    case off, notStarted, working, needsConfirm, blocked, discuss, replied, idle(Int)

    var label: String {
        switch self {
        case .off:          return "휴식"
        case .notStarted:   return "브리프 대기"
        case .working:      return "작업중"
        case .needsConfirm: return "컨펌 대기"
        case .blocked:      return "막힘"
        case .discuss:      return "논의 요청"
        case .replied:      return "답장 처리중"
        case .idle(let m):  return m >= 60 ? "유휴 \(m / 60)시간" : "유휴 \(m)분"
        }
    }
    // 색은 상태에만 (잔잔 규칙 3): 컨펌 대기·논의 = 호박, 막힘 = 적. 나머지는 종이색 알약.
    var color: NSColor? {
        switch self {
        case .needsConfirm, .discuss: return waitingColor
        case .blocked:                return blockedColor
        default:                      return nil
        }
    }
    var bounce: CGFloat {
        switch self {
        case .working: return 3
        case .needsConfirm, .blocked, .discuss: return 9
        case .replied: return 4
        default: return 0
        }
    }
    var speed: CGFloat {
        switch self {
        case .needsConfirm, .blocked, .discuss: return 0.28
        default: return 0.10
        }
    }
    var alert: Bool {
        switch self { case .needsConfirm, .blocked, .discuss: return true; default: return false }
    }
}

struct Instance: Equatable { let key: String; let role: Role; let suffix: String
    static func == (a: Instance, b: Instance) -> Bool { a.key == b.key }
}

func discoverInstances() -> [Instance] {
    let briefs = teamDir.appendingPathComponent("briefs")
    let names = (try? FileManager.default.contentsOfDirectory(atPath: briefs.path)) ?? []
    var out: [Instance] = []
    for role in roles {
        out.append(Instance(key: role.key, role: role, suffix: ""))
        // 분신(builder2 …)은 브리프가 24시간 내에 갱신된 것만 — 8월 브리프가 남아 있어도 안 띄운다
        let numbered: [Instance] = names.compactMap { n in
            guard n.hasPrefix(role.key), n.hasSuffix(".md") else { return nil }
            let mid = n.dropFirst(role.key.count).dropLast(3)
            guard !mid.isEmpty, mid.allSatisfy({ $0.isNumber }) else { return nil }
            let m = mtime(briefs.appendingPathComponent(n)) ?? .distantPast
            guard Date().timeIntervalSince(m) < 24 * 3600 else { return nil }
            return Instance(key: role.key + mid, role: role, suffix: String(mid))
        }
        out.append(contentsOf: numbered.sorted { $0.key < $1.key })
    }
    return out
}

// MARK: - 세션 활동 신호 (2026-09-03)
//
// 보고 파일만 보면 긴 슬라이스 중(코드 읽기·테스트)에 "유휴"로 오판한다. Claude Code는 매 턴 세션 기록
// ~/.claude/projects/{프로젝트 경로 인코딩}/{세션}.jsonl 을 갱신하고, 그 안에 `-n` 세션명(customTitle)이 남는다.
// → 세션명에 이 워커 이름(별칭 포함)이 들어간 기록의 mtime = "탭이 실제로 움직인 시각". 읽기 전용.

let projectRoot = teamDir.deletingLastPathComponent().deletingLastPathComponent()
let sessionsDir: URL = {
    let enc = projectRoot.path.map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined()
    return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".claude/projects/\(enc)")
}()
var titleCache: [String: String] = [:]   // jsonl 경로 → 세션명
func sessionTitle(_ url: URL) -> String {
    if let t = titleCache[url.path] { return t }
    guard let h = try? FileHandle(forReadingFrom: url) else { return "" }
    defer { try? h.close() }
    let head = String(decoding: h.readData(ofLength: 256 * 1024), as: UTF8.self)
    var title = ""
    if let r = head.range(of: "\"customTitle\":\"") {
        title = String(head[r.upperBound...].prefix(while: { $0 != "\"" }))
    }
    if !title.isEmpty { titleCache[url.path] = title }
    return title
}
/// 세션 기록 끝부분에서 "모델이 실제로 산출한 마지막 턴"(텍스트·도구 호출, API 오류 제외)과 "마지막 API 오류" 시각.
/// 사용자가 "이어서"를 친 것, 529 Overloaded 같은 오류 턴은 활동이 아니다 (2026-09-03 밤, 번뜩 오판 사례).
let isoFmt: ISO8601DateFormatter = { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f }()
let isoFmtPlain = ISO8601DateFormatter()
func parseTS(_ s: String) -> Date? { isoFmt.date(from: s) ?? isoFmtPlain.date(from: s) }
func lastRealTurn(_ url: URL) -> (work: Date?, error: Date?) {
    guard let h = try? FileHandle(forReadingFrom: url), let size = try? h.seekToEnd() else { return (nil, nil) }
    defer { try? h.close() }
    let span: UInt64 = 128 * 1024
    try? h.seek(toOffset: size > span ? size - span : 0)
    let tail = String(decoding: h.readDataToEndOfFile(), as: UTF8.self)
    var work: Date?, err: Date?
    for line in tail.split(separator: "\n").reversed() {
        guard line.contains("\"type\":\"assistant\""), let d = line.data(using: .utf8),
              let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
              let ts = (j["timestamp"] as? String).flatMap(parseTS),
              let msg = j["message"] as? [String: Any] else { continue }
        var isError = false, isWork = false
        if let parts = msg["content"] as? [[String: Any]] {
            for p in parts {
                if p["type"] as? String == "tool_use" { isWork = true }
                if p["type"] as? String == "text", let t = p["text"] as? String {
                    if t.hasPrefix("API Error") { isError = true } else if !t.isEmpty { isWork = true }
                }
            }
        } else if let t = msg["content"] as? String {
            if t.hasPrefix("API Error") { isError = true } else if !t.isEmpty { isWork = true }
        }
        if isError, err == nil { err = ts }
        if isWork { work = ts; break }
    }
    return (work, err)
}
/// 이 인스턴스 이름으로 시작하는 세션 기록들 중 가장 최근 실제 턴 / 그 뒤의 API 오류. "몽글 0903"은 몽글2와 구분한다.
func lastSessionActivity(_ inst: Instance) -> (work: Date?, error: Date?) {
    guard let files = try? FileManager.default.contentsOfDirectory(at: sessionsDir, includingPropertiesForKeys: [.contentModificationDateKey]) else { return (nil, nil) }
    let names = ([inst.role.name, inst.role.key] + inst.role.aliases).map { $0 + inst.suffix }
    var bestWork: Date?, bestErr: Date?
    for f in files where f.pathExtension == "jsonl" {
        guard let m = mtime(f), Date().timeIntervalSince(m) < 12 * 3600 else { continue }   // 오늘 것만 훑는다
        // 세션명은 "🔥번뜩 0903 · …" 꼴 — 앞의 이모지를 떼고 워커 이름으로 *시작*해야 한다.
        let t = String(sessionTitle(f).drop(while: { !$0.isLetter && !$0.isNumber }))
        guard names.contains(where: { n in
            guard t.hasPrefix(n) else { return false }
            let after = t.dropFirst(n.count).first
            return after == nil || !(after!.isNumber)      // 이름 뒤에 숫자가 이어지면 다른 분신
        }) else { continue }
        let r = lastRealTurn(f)
        if let w = r.work, bestWork == nil || w > bestWork! { bestWork = w }
        if let e = r.error, bestErr == nil || e > bestErr! { bestErr = e }
    }
    if let e = bestErr, let w = bestWork, e < w { bestErr = nil }   // 오류 뒤에 정상 턴이 있으면 해소된 것
    return (bestWork, bestErr)
}

struct Snapshot { let state: PetState; let tooltip: String; let openTarget: URL? }

func snapshot(_ inst: Instance) -> Snapshot {
    let brief  = teamDir.appendingPathComponent("briefs/\(inst.key).md")
    let report = teamDir.appendingPathComponent("reports/\(inst.key).md")
    let req    = teamDir.appendingPathComponent("confirm/\(inst.key).request.md")
    let reply  = teamDir.appendingPathComponent("confirm/\(inst.key).reply.md")
    let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"

    guard let bm = mtime(brief) else {
        return Snapshot(state: .off, tooltip: "브리프 없음", openTarget: mtime(report) != nil ? report : nil)
    }
    let title = firstLine(brief)
    if let rqm = mtime(req) {
        if let rpm = mtime(reply), rpm >= rqm {
            return Snapshot(state: .replied, tooltip: "\(title)\n답장 \(fmt.string(from: rpm))", openTarget: reply)
        }
        let head = firstLine(req).uppercased()
        let st: PetState = head.hasPrefix("BLOCKED") ? .blocked : head.hasPrefix("DISCUSS") ? .discuss : .needsConfirm
        return Snapshot(state: st, tooltip: "\(title)\n요청 \(fmt.string(from: rqm))", openTarget: req)
    }
    // 활동 시각 = 보고 파일과 세션 기록 중 더 최근 — 보고는 안 썼어도 탭이 움직이면 작업중
    let act = lastSessionActivity(inst)
    let sess = act.work
    let rm = mtime(report)
    var sessNote = sess.map { "\n탭 활동 \(fmt.string(from: $0))" } ?? "\n탭 기록 없음"
    if let e = act.error { sessNote += "\n⚠️ API 오류 \(fmt.string(from: e)) — 탭에서 이어서 필요" }
    guard let activity = [rm, sess].compactMap({ $0 }).max(), activity > bm else {
        return Snapshot(state: .notStarted, tooltip: "\(title)\n브리프 \(fmt.string(from: bm))\(sessNote)", openTarget: brief)
    }
    let gap = Int(Date().timeIntervalSince(activity) / 60)
    let st: PetState = gap >= idleMinutes ? .idle(gap) : .working
    let reportNote = rm.map { "보고 \(fmt.string(from: $0))" } ?? "보고 없음"
    return Snapshot(state: st, tooltip: "\(title)\n\(reportNote)\(sessNote)", openTarget: rm != nil ? report : brief)
}

// MARK: - 뷰
//
// "말 없는 펫" (2026-09-03): 평소엔 글자가 없다. 상태는 마스코트 자체로 —
//   작업중·답장 처리중 = 살짝 움직임 / 유휴·브리프 대기·휴식 = 눈 감음 /
//   컨펌 대기·논의 = 호박 테두리 발광 + 말풍선 / 막힘 = 적 발광 + 말풍선
// 글자(말풍선)는 사람이 행동해야 할 때와 엿보기(한 번 클릭, 3초)에만 뜬다. 이름은 툴팁, 분신은 숫자 배지.

var appController: PetController?
var peekUntil: Date?   // 엿보기 — 모든 펫이 말풍선을 잠시 보여준다
func alwaysBubbles() -> Bool { UserDefaults.standard.bool(forKey: "madang.bubbles") }   // 메뉴 "말풍선 항상 표시"

func mascotImage(_ id: String, variant: String = "") -> NSImage? {
    NSImage(contentsOf: mascotDir.appendingPathComponent(id + variant + (isDark() ? "@dark" : "") + ".svg"))
}

/// 종이색 말풍선(꼬리 아래) + 잉크 글자 — 단색 바탕이라 어떤 배경에서도 읽힌다
final class BubbleView: NSView {
    var text = NSAttributedString()
    let tail: CGFloat = 7
    func set(_ str: String, color: NSColor) {
        let p = NSMutableParagraphStyle(); p.alignment = .center
        text = NSAttributedString(string: str, attributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold), .foregroundColor: color, .paragraphStyle: p])
        let w = ceil(text.size().width) + 18
        frame.size = NSSize(width: max(w, 44), height: 24 + tail)
        needsDisplay = true
    }
    override func draw(_ rect: NSRect) {
        let pal = Palette.current
        let body = NSRect(x: 0.5, y: tail + 0.5, width: bounds.width - 1, height: bounds.height - tail - 1)
        let path = NSBezierPath(roundedRect: body, xRadius: 8, yRadius: 8)
        let cx = bounds.midX
        path.move(to: NSPoint(x: cx - 6, y: tail + 0.5))
        path.line(to: NSPoint(x: cx, y: 0.5))
        path.line(to: NSPoint(x: cx + 6, y: tail + 0.5))
        pal.paper.withAlphaComponent(0.97).setFill(); path.fill()
        pal.ink.withAlphaComponent(0.18).setStroke(); path.lineWidth = 1; path.stroke()
        let ts = text.size()
        text.draw(at: NSPoint(x: (bounds.width - ts.width) / 2, y: tail + (body.height - ts.height) / 2 + 0.5))
    }
}

final class PetView: NSView {
    let inst: Instance
    let emoji = NSTextField(labelWithString: "")   // SVG 없을 때 폴백
    let figure = NSImageView()
    let num = NSTextField(labelWithString: "")     // 분신 번호
    let bubble = BubbleView()
    var state: PetState = .off
    var openTarget: URL?
    var phase: CGFloat = .random(in: 0...6)
    var smileUntil: Date?
    var prevState: PetState = .off
    var themedDark = isDark()
    let figureBaseY: CGFloat = 18, figureH: CGFloat = 78

    init(_ inst: Instance) {
        self.inst = inst
        super.init(frame: NSRect(x: 0, y: 0, width: petW, height: petH))
        wantsLayer = true

        if mascotImage(inst.role.id) != nil {
            figure.imageScaling = .scaleProportionallyUpOrDown
            figure.frame = NSRect(x: 9, y: figureBaseY, width: petW - 18, height: figureH)
            addSubview(figure)
        } else {
            emoji.font = .systemFont(ofSize: 46); emoji.alignment = .center
            emoji.stringValue = inst.role.emoji
            emoji.frame = NSRect(x: 0, y: figureBaseY, width: petW, height: 60)
            addSubview(emoji)
        }
        figure.wantsLayer = true   // 상태 색은 실루엣 발광으로, 평소엔 부드러운 그림자 (테두리 없음)

        if !inst.suffix.isEmpty {
            num.font = .systemFont(ofSize: 9, weight: .bold); num.alignment = .center
            num.stringValue = inst.suffix
            num.wantsLayer = true; num.layer?.cornerRadius = 7
            num.frame = NSRect(x: petW - 24, y: figureBaseY - 2, width: 14, height: 14)
            addSubview(num)
        }
        bubble.isHidden = true
        addSubview(bubble)
        retheme()
    }
    required init?(coder: NSCoder) { fatalError() }

    // 마우스를 올리면 그 펫만 말풍선 (클릭 없이 바로)
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil))
    }
    override func mouseEntered(with event: NSEvent) { hovered = true; refreshBubble() }
    override func mouseExited(with event: NSEvent) { hovered = false; refreshBubble() }

    var variant: String {
        if smileUntil != nil { return "-smile" }
        switch state {
        case .off, .notStarted, .idle: return "-sleep"      // 잠
        case .working, .replied:       return "-work"       // 집중 — 눈이 커지고 눈동자에 자기 도형
        default:                       return ""            // 깨어 있음 — 컨펌 대기·막힘·논의
        }
    }
    var hovered = false
    var showBubble: Bool { state.alert || alwaysBubbles() || hovered || (peekUntil.map { Date() < $0 } ?? false) }

    func retheme() {
        themedDark = isDark()
        let pal = Palette.current
        figure.image = mascotImage(inst.role.id, variant: variant)
        setGlow(state.color)
        num.textColor = pal.paper; num.layer?.backgroundColor = pal.ink.withAlphaComponent(0.85).cgColor
        refreshBubble()
    }
    func refreshBubble() {
        bubble.set(state.label, color: state.color ?? Palette.current.ink)
        bubble.frame.origin = NSPoint(x: (petW - bubble.frame.width) / 2, y: petH - bubble.frame.height - 2)
        bubble.isHidden = !showBubble
    }

    func apply(_ s: Snapshot) {
        let changed = s.state != state
        state = s.state
        openTarget = s.openTarget
        toolTip = "\(inst.role.name)\(inst.suffix) — \(s.state.label)\n\(s.tooltip)"
        alphaValue = (s.state == .off) ? 0.5 : 1.0
        setGlow(s.state.color)
        if themedDark != isDark() { retheme() } else if changed || smileUntil == nil { figure.image = mascotImage(inst.role.id, variant: variant); refreshBubble() }
        if changed, s.state == .working, [PetState.notStarted, .off].contains(prevState) { spinOnce() }
        prevState = s.state
    }

    func tick() {
        phase += state.speed
        let dy = state.bounce * CGFloat(sin(Double(phase)))
        let y = figureBaseY + max(dy, -state.bounce * 0.3)
        figure.frame.origin.y = y; emoji.frame.origin.y = y
        if let until = smileUntil, Date() > until {   // 미소는 1회 전이 — 3초 뒤 복귀
            smileUntil = nil
            figure.image = mascotImage(inst.role.id, variant: variant)
        }
        let want = showBubble
        if bubble.isHidden == want { refreshBubble() }
    }

    // 컨펌 대기·논의 = 호박, 막힘 = 적으로 실루엣 가장자리가 빛난다. 정적 — 깜빡이지 않는다.
    func setGlow(_ color: NSColor?) {
        guard let l = figure.layer else { return }
        if let c = color {
            l.shadowColor = c.cgColor; l.shadowOpacity = 1; l.shadowRadius = 7; l.shadowOffset = .zero
        } else {
            // 평소: 테두리 없음(SVG는 실루엣만) — 바탕과 분리는 본체 반대색의 부드러운 그림자가 맡는다
            l.shadowColor = Palette.current.paper.cgColor; l.shadowOpacity = 0.45; l.shadowRadius = 4; l.shadowOffset = .zero
        }
    }

    // 시동: 잠에서 깨어 일을 시작하는 순간 제자리에서 살짝 기울었다 돌아온다 (1회, 0.9초 — 한 바퀴는 튄다는 사용자 피드백)
    func spinOnce() {
        guard let l = figure.layer else { return }
        l.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        l.position = CGPoint(x: figure.frame.midX, y: figure.frame.midY)
        let a = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        let d = Double.pi / 180
        a.values = [0, -9 * d, 6 * d, -2 * d, 0]
        a.keyTimes = [0, 0.3, 0.6, 0.85, 1]
        a.duration = 0.9
        a.timingFunctions = Array(repeating: CAMediaTimingFunction(name: .easeInEaseOut), count: 4)
        l.add(a, forKey: "wake")
    }

    // 작업 완료·APPROVE 순간에만 웃는다 (잔잔 규칙 2)
    func smile(seconds: TimeInterval = 3) {
        smileUntil = Date().addingTimeInterval(seconds)
        figure.image = mascotImage(inst.role.id, variant: "-smile")
    }

    // 펫 박스 전체가 드래그 영역. 한 번 클릭(안 움직임) = 전원 엿보기 2.5초, 더블클릭 = 파일 열기
    override func hitTest(_ point: NSPoint) -> NSView? { frame.contains(point) ? self : nil }
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 { openFile(); return }
        let before = window?.frame.origin
        window?.performDrag(with: event)
        if before == window?.frame.origin { peekUntil = Date().addingTimeInterval(2.5) }   // 엿보기 2.5초 — 세 개 훑기엔 충분, 거슬리진 않는 길이
    }
    // 우클릭 = 메뉴 (상단바 👾가 넘쳐서 안 보일 때의 조작 경로)
    override func rightMouseDown(with event: NSEvent) {
        guard let c = appController else { return }
        NSMenu.popUpContextMenu(c.buildMenu(), with: event, for: self)
    }
    @objc func openFile() {
        if let u = openTarget { NSWorkspace.shared.open(u) }
    }
}

// MARK: - 컨트롤러

final class PetController: NSObject {
    let panel: NSPanel
    let container = NSView()
    var pets: [PetView] = []
    var lastStates: [String: PetState] = [:]
    var statusItem: NSStatusItem!
    let silent = ProcessInfo.processInfo.environment["MADANG_SILENT"] != nil

    override init() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: petW, height: petH),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        super.init()
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        container.wantsLayer = true
        panel.contentView = container

        rebuild()
        restoreOrigin()
        panel.orderFrontRegardless()

        NotificationCenter.default.addObserver(self, selector: #selector(saveOrigin),
                                               name: NSWindow.didMoveNotification, object: panel)
        Timer.scheduledTimer(withTimeInterval: pollSeconds, repeats: true) { [weak self] _ in self?.refresh() }
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.pets.forEach { $0.tick() }
        }
        setupStatusItem()
    }

    func rebuild() {
        let insts = discoverInstances()
        if insts.map(\.key) == pets.map(\.inst.key) { refreshStates(); return }
        pets.forEach { $0.removeFromSuperview() }
        pets = insts.map(PetView.init)
        let w = CGFloat(pets.count) * petW + 8
        let origin = panel.frame.origin
        panel.setContentSize(NSSize(width: w, height: petH))
        panel.setFrameOrigin(origin)
        for (i, p) in pets.enumerated() {
            p.frame.origin = NSPoint(x: 4 + CGFloat(i) * petW, y: 0)
            container.addSubview(p)
        }
        refreshStates()
    }

    func refresh() { rebuild() }

    func refreshStates() {
        for p in pets {
            let s = snapshot(p.inst)
            let prev = lastStates[p.inst.key]
            p.apply(s)
            if s.state.alert, prev != nil, prev != s.state, !silent {
                NSSound(named: NSSound.Name("Pop"))?.play()
            }
            if s.state == .replied, prev != nil, prev != .replied,
               let reply = s.openTarget, firstLine(reply).uppercased().hasPrefix("APPROVE") {
                p.smile()
            }
            lastStates[p.inst.key] = s.state
        }
    }

    // 위치 기억
    var originKey: String { "madang.origin." + teamDir.path }
    @objc func saveOrigin() {
        UserDefaults.standard.set([panel.frame.origin.x, panel.frame.origin.y], forKey: originKey)
    }
    func restoreOrigin() {
        if let a = UserDefaults.standard.array(forKey: originKey) as? [CGFloat], a.count == 2 {
            panel.setFrameOrigin(NSPoint(x: a[0], y: a[1]))
        } else { resetOrigin() }
    }
    @objc func resetOrigin() {
        guard let s = NSScreen.main?.visibleFrame else { return }
        panel.setFrameOrigin(NSPoint(x: s.maxX - panel.frame.width - 24, y: s.minY + 24))
        saveOrigin()
    }

    func buildMenu() -> NSMenu {
        let menu = NSMenu()
        let path = NSMenuItem(title: teamDir.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent, action: nil, keyEquivalent: "")
        path.isEnabled = false
        menu.addItem(path)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "위치 초기화 (우하단)", action: #selector(resetOrigin), keyEquivalent: ""))
        let ink = NSMenu()
        for (t, v) in [("흰색", "white"), ("검정", "black"), ("자동 (시스템 외양)", "auto")] {
            let it = NSMenuItem(title: t, action: #selector(setInk(_:)), keyEquivalent: "")
            it.representedObject = v; it.state = inkMode() == v ? .on : .off; it.target = self
            ink.addItem(it)
        }
        let inkItem = NSMenuItem(title: "마스코트 잉크", action: nil, keyEquivalent: "")
        inkItem.submenu = ink
        menu.addItem(inkItem)
        let bub = NSMenuItem(title: "말풍선 항상 표시", action: #selector(toggleBubbles(_:)), keyEquivalent: "")
        bub.state = alwaysBubbles() ? .on : .off
        menu.addItem(bub)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "종료", action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { if $0.target == nil { $0.target = self } }
        return menu
    }
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "👾"
        statusItem.menu = buildMenu()
    }
    @objc func setInk(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.representedObject as? String ?? "white", forKey: "madang.ink")
        pets.forEach { $0.retheme() }
        statusItem.menu = buildMenu()
    }
    @objc func toggleBubbles(_ sender: NSMenuItem) {
        UserDefaults.standard.set(!alwaysBubbles(), forKey: "madang.bubbles")
        pets.forEach { $0.refreshBubble() }
        statusItem.menu = buildMenu()
    }
    @objc func quit() { NSApp.terminate(nil) }
}

// MARK: - 실행

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let controller = PetController()
appController = controller
app.run()
