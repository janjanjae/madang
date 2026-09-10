// madang.swift — 마당(madang) 팀 데스크톱 워커 오버레이 (REGISTRY E-17 L1+L2, v0 2026-09-02 · 마스코트 v1 2026-09-03 · 상태 4신호·5라벨 2026-09-10)
//
// 화면 위에 떠 있는 작은 창에 워커(번뜩·몽글·슥슥)를 띄우고,
// `.claude/team/` 파일 신호만 읽어 상태를 말풍선으로 보여준다. 읽기 전용 — 팀 파일을 절대 쓰지 않는다.
//
// 상태 판정은 teamleader/reference/confirm-protocol.md 의 Monitor 스크립트와 같은 규칙을 4신호·5라벨로 압축한다:
//   request 있음 + reply 없거나 오래됨 → 컨펌 대기(CONFIRM) / 논의(DISCUSS) = 호박 발광 · 사람 필요(BLOCKED) = 적 발광
//   request 있음 + reply 더 새로움      → 작업중(답장 처리중 — 미소는 APPROVE 순간의 전이 애니메이션으로만 표현)
//   보고가 브리프보다 오래됨            → 작업중(시동 — 아직 탭이 움직이지 않은 막 받은 브리프)
//   보고·세션 기록 모두 25분 이상 정지 → 쉼 N분 (세션 기록 = ~/.claude/projects/…/*.jsonl mtime, 2026-09-03)
//   그 외                               → 작업중
//   브리프 파일 없음                    → 쉼
//
// 빌드: ./build.sh   실행: madang <프로젝트>/.claude/team   (인자 없으면 $PWD/.claude/team)
// 조작: 드래그로 이동 · 더블클릭 = request/보고 파일 열기 · 메뉴바 아이콘(도담) = 위치 초기화/종료
// 환경: MADANG_SILENT=1 이면 컨펌·막힘 전환 시 효과음 없음

import AppKit
import Foundation

// MARK: - 설정

let idleMinutes = 25          // Monitor 스크립트와 동일
let pollSeconds = 3.0
let workerW: CGFloat = 96, workerH: CGFloat = 132
// 말풍선이 2~3줄로 자랄 때 워커 머리를 덮지 않도록 패널에 미리 얹어 두는 고정 여유 높이(결함 3, 2026-09-10).
// 패널의 실제 프레임(kCGWindowBounds)은 이제 상태와 무관하게 상수다(직접 실측 확인) — 다만 투명/보더리스
// 창이라 `screencapture -l`은 창 프레임이 아니라 그려진 픽셀의 바운딩 박스로 크롭하므로, 말풍선이 뜬
// 캡처는 여전히 더 커 보인다. make-hero-gif.sh의 프레임별 최대값 정렬은 그래서 그대로 남아 있다.
let bubbleHeadroom: CGFloat = 80
let panelH: CGFloat = workerH + bubbleHeadroom

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
        guard (r["worker"] as? Bool) == true, let id = r["id"] as? String, let key = r["key"] as? String,
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
    // 트림을 먼저 해야 "# " 앞에 공백이 있는 줄도 H1 규칙(^#+\s*)이 걸린다 — displayTitle이 이 결과를
    // 그대로 받아쓰므로 여기서 확실히 벗겨야 한다(2026-09-05 리뷰 결함 8, displayTitle과 통일).
    return line.trimmingCharacters(in: .whitespaces)
               .replacingOccurrences(of: "**", with: "")
               .replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
               .trimmingCharacters(in: .whitespaces)
}

// MARK: - 상태 (4신호·5라벨, 2026-09-10 축소 — 경위는 plans/ 참조)
//
// 원래 8종(off·notStarted·working·needsConfirm·blocked·discuss·replied·idle)을 시각 신호 4개로 접는다:
//   attention(discuss:) — 호박 발광 + 말풍선. discuss=false(컨펌 대기)/true(논의)
//   blocked             — 적 발광 + 말풍선. "사람 필요"(v1에서 권한 대기 합류 예정)
//   working             — 눈 반사광. 원래 working·notStarted(시동)·replied(답장 처리중) 전부 흡수
//   resting(Int?)        — 눈 감음. nil=브리프 없음(쉼) · N=유휴 분(쉼 N분)
// replied의 미소는 상태에서 빠지고 WorkerView.apply()의 전이 애니메이션(2~3초)으로만 남는다.
enum WorkerState: Equatable {
    case working, attention(discuss: Bool), blocked, resting(Int?)

    var label: String {
        switch self {
        case .working:                return "작업중"
        case .attention(let discuss): return discuss ? "논의" : "컨펌 대기"
        case .blocked:                 return "사람 필요"
        case .resting(let m):
            guard let m else { return "쉼" }
            return m >= 60 ? "쉼 \(m / 60)시간" : "쉼 \(m)분"
        }
    }
    // 색은 상태에만 (잔잔 규칙 3): 컨펌 대기·논의 = 호박, 사람 필요 = 적. 나머지는 종이색 알약.
    var color: NSColor? {
        switch self {
        case .attention: return waitingColor
        case .blocked:   return blockedColor
        default:         return nil
        }
    }
    var bounce: CGFloat {
        switch self {
        case .working:            return 3
        case .attention, .blocked: return 9
        case .resting:            return 0
        }
    }
    var speed: CGFloat {
        switch self {
        case .attention, .blocked: return 0.28
        default:                   return 0.10
        }
    }
    var alert: Bool {
        switch self { case .attention, .blocked: return true; default: return false }
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

// MARK: - 세션 활동 신호 (2026-09-03, 결함 2·6·7 수정 2026-09-10)
//
// 보고 파일만 보면 긴 슬라이스 중(코드 읽기·테스트)에 "쉼"으로 오판한다. Claude Code는 매 턴 세션 기록
// ~/.claude/projects/{프로젝트 경로 인코딩}/{세션}.jsonl 을 갱신하고, 그 안에 `-n` 세션명(customTitle)이 남는다.
// → 세션명에 이 워커 이름(별칭 포함)이 들어간 기록의 mtime = "탭이 실제로 움직인 시각". 읽기 전용.

let projectRoot = teamDir.deletingLastPathComponent().deletingLastPathComponent()
// Claude Code의 실제 인코딩 규칙은 "ASCII 영숫자가 아니면 전부 -"([^a-zA-Z0-9]) — .isLetter/.isNumber는
// 유니코드 전반(한글 포함)을 "글자"로 인정해 버려, 한글이 든 프로젝트 경로에서 세션 폴더를 못 찾았다(결함 2).
let asciiAlnum = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
let sessionsDir: URL = {
    let enc = projectRoot.path.unicodeScalars.map { asciiAlnum.contains($0) ? String($0) : "-" }.joined()
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
let isoFmt: ISO8601DateFormatter = { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f }()
let isoFmtPlain = ISO8601DateFormatter()
func parseTS(_ s: String) -> Date? { isoFmt.date(from: s) ?? isoFmtPlain.date(from: s) }

/// "지금 뭐 하나" 요약 한 줄 — 도구 호출은 딕셔너리 전체를 문자열화하면 장문이 새므로 자주 쓰는
/// 키만 뽑아 200자로 캡(결함 6). 원문에 개행이 있으면 줄마다 목록·헤딩 기호를 벗기고 공백으로 접는다.
func oneLine(_ s: String, limit: Int) -> String {
    let t = s.split(separator: "\n", omittingEmptySubsequences: true).map { line -> String in
        var l = line.trimmingCharacters(in: .whitespaces)
        for p in ["- ", "# ", "## ", "### "] where l.hasPrefix(p) { l = String(l.dropFirst(p.count)); break }
        return l
    }.joined(separator: " ")
        .replacingOccurrences(of: "**", with: "")
        .replacingOccurrences(of: "`", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return t.count > limit ? String(t.prefix(limit)) + "…" : t
}
func toolInputSummary(_ input: [String: Any]?) -> String {
    guard let input else { return "" }
    let keys = ["file_path", "command", "pattern", "description"]
    let parts = keys.compactMap { k in (input[k] as? String).map { "\(k)=\($0)" } }
    return String(parts.joined(separator: " ").prefix(200))
}

struct TailScan { let work: Date?; let error: Date?; let summary: String? }

/// 세션 기록 끝부분 128KB에서 "모델이 실제로 산출한 마지막 턴"(텍스트·도구 호출, API 오류 제외)과
/// "마지막 API 오류" 시각, 그리고 그 마지막 턴의 요약을 **한 번의 스캔**으로 함께 뽑는다.
/// (2026-09-05엔 판정(work/error)과 요약을 별도 함수 2개가 각자 훑어 같은 파일을 최대 3번 읽었다 — 결함 7)
/// 사용자가 "이어서"를 친 것, 529 Overloaded 같은 오류 턴은 활동이 아니다 (2026-09-03 밤, 번뜩 오판 사례).
func scanTail(_ url: URL) -> TailScan {
    guard let h = try? FileHandle(forReadingFrom: url), let size = try? h.seekToEnd() else { return TailScan(work: nil, error: nil, summary: nil) }
    defer { try? h.close() }
    let span: UInt64 = 128 * 1024
    try? h.seek(toOffset: size > span ? size - span : 0)
    let tail = String(decoding: h.readDataToEndOfFile(), as: UTF8.self)
    var work: Date?, err: Date?, summary: String?
    for line in tail.split(separator: "\n").reversed() {
        guard line.contains("\"type\":\"assistant\""), let d = line.data(using: .utf8),
              let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
              let ts = (j["timestamp"] as? String).flatMap(parseTS),
              let msg = j["message"] as? [String: Any] else { continue }
        var isError = false, isWork = false, text: String?
        if let parts = msg["content"] as? [[String: Any]] {
            for p in parts {
                if p["type"] as? String == "tool_use", let name = p["name"] as? String {
                    isWork = true
                    if text == nil { text = "\(name): \(oneLine(toolInputSummary(p["input"] as? [String: Any]), limit: 40))" }
                }
                if p["type"] as? String == "text", let t = p["text"] as? String {
                    if t.hasPrefix("API Error") { isError = true } else if !t.isEmpty { isWork = true; if text == nil { text = oneLine(t, limit: 60) } }
                }
            }
        } else if let t = msg["content"] as? String {
            if t.hasPrefix("API Error") { isError = true } else if !t.isEmpty { isWork = true; text = oneLine(t, limit: 60) }
        }
        if isError, err == nil { err = ts }
        if isWork { work = ts; summary = text; break }
    }
    return TailScan(work: work, error: err, summary: summary)
}
/// 다른 코드(활동 신호 스크립트 등)가 (work, error) 시그니처를 참조할 수 있어 래퍼로 유지한다 —
/// 실제 스캔은 scanTail 하나로 통합됐다(결함 7, 판정 반환 의미는 그대로).
func lastRealTurn(_ url: URL) -> (work: Date?, error: Date?) {
    let r = scanTail(url); return (r.work, r.error)
}

struct ActivityInfo { let work: Date?; let error: Date?; let summary: String? }

/// 이 인스턴스 이름으로 시작하는 세션 기록들 중 가장 최근 실제 턴 / 그 뒤의 API 오류 / 그 턴의 요약을
/// 파일마다 **한 번의 scanTail 호출**로 함께 얻는다. "몽글 0903"은 몽글2와 구분한다.
func lastSessionActivity(_ inst: Instance) -> ActivityInfo {
    guard let files = try? FileManager.default.contentsOfDirectory(at: sessionsDir, includingPropertiesForKeys: [.contentModificationDateKey]) else { return ActivityInfo(work: nil, error: nil, summary: nil) }
    let names = ([inst.role.name, inst.role.key] + inst.role.aliases).map { $0 + inst.suffix }
    var bestWork: Date?, bestErr: Date?, bestSummary: String?
    for f in files where f.pathExtension == "jsonl" {
        guard let m = mtime(f), Date().timeIntervalSince(m) < 12 * 3600 else { continue }   // 오늘 것만 훑는다
        // 세션명은 "🔥번뜩 0903 · …" 꼴 — 앞의 이모지를 떼고 워커 이름으로 *시작*해야 한다.
        let t = String(sessionTitle(f).drop(while: { !$0.isLetter && !$0.isNumber }))
        guard names.contains(where: { n in
            guard t.hasPrefix(n) else { return false }
            let after = t.dropFirst(n.count).first
            return after == nil || !(after!.isNumber)      // 이름 뒤에 숫자가 이어지면 다른 분신
        }) else { continue }
        let r = scanTail(f)
        if let w = r.work, bestWork == nil || w > bestWork! { bestWork = w; bestSummary = r.summary }
        if let e = r.error, bestErr == nil || e > bestErr! { bestErr = e }
    }
    if let e = bestErr, let w = bestWork, e < w { bestErr = nil }   // 오류 뒤에 정상 턴이 있으면 해소된 것
    return ActivityInfo(work: bestWork, error: bestErr, summary: bestSummary)
}

struct Snapshot { let state: WorkerState; let tooltip: String; let openTarget: URL?; let title: String; let summary: String?; let replyEvent: Date? }

func snapshot(_ inst: Instance) -> Snapshot {
    let brief  = teamDir.appendingPathComponent("briefs/\(inst.key).md")
    let report = teamDir.appendingPathComponent("reports/\(inst.key).md")
    let req    = teamDir.appendingPathComponent("confirm/\(inst.key).request.md")
    let reply  = teamDir.appendingPathComponent("confirm/\(inst.key).reply.md")
    let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"

    // 브리프가 아예 없으면 세션 스캔 자체가 낭비 — 조기 반환으로 건너뛴다(결함 7).
    guard let bm = mtime(brief) else {
        return Snapshot(state: .resting(nil), tooltip: "브리프 없음", openTarget: mtime(report) != nil ? report : nil, title: "", summary: nil, replyEvent: nil)
    }
    let title = firstLine(brief)
    let act = lastSessionActivity(inst)   // work/error/summary 한 번에
    if let rqm = mtime(req) {
        if let rpm = mtime(reply), rpm >= rqm {
            // 답장 처리중 — 원래 별도 상태였으나 지금은 "작업중"에 흡수(눈 반사광 동일). APPROVE 미소는
            // replyEvent를 본 WorkerView.apply()가 전이 애니메이션으로만 처리한다.
            return Snapshot(state: .working, tooltip: "\(title)\n답장 \(fmt.string(from: rpm))", openTarget: reply, title: title, summary: act.summary, replyEvent: rpm)
        }
        // BLOCKED/DISCUSS 키워드가 인사말 뒤 등 첫 줄 어디에 있어도 잡는다(hasPrefix→contains, 결함 1)
        let head = firstLine(req).uppercased()
        let st: WorkerState = head.contains("BLOCKED") ? .blocked : .attention(discuss: head.contains("DISCUSS"))
        return Snapshot(state: st, tooltip: "\(title)\n요청 \(fmt.string(from: rqm))", openTarget: req, title: title, summary: act.summary, replyEvent: nil)
    }
    // 활동 시각 = 보고 파일과 세션 기록 중 더 최근 — 보고는 안 썼어도 탭이 움직이면 작업중
    let sess = act.work
    let rm = mtime(report)
    var sessNote = sess.map { "\n탭 활동 \(fmt.string(from: $0))" } ?? "\n탭 기록 없음"
    if let e = act.error { sessNote += "\n⚠️ API 오류 \(fmt.string(from: e)) — 탭에서 이어서 필요" }
    guard let activity = [rm, sess].compactMap({ $0 }).max(), activity > bm else {
        // 시동 — 브리프는 받았지만 아직 탭이 움직이지 않음. 원래 "브리프 대기"로 눈을 감았으나
        // 지금은 "작업중"(눈 반사광)에 흡수됐다(AC A).
        return Snapshot(state: .working, tooltip: "\(title)\n브리프 \(fmt.string(from: bm))\(sessNote)", openTarget: brief, title: title, summary: act.summary, replyEvent: nil)
    }
    let gap = Int(Date().timeIntervalSince(activity) / 60)
    let st: WorkerState = gap >= idleMinutes ? .resting(gap) : .working
    let reportNote = rm.map { "보고 \(fmt.string(from: $0))" } ?? "보고 없음"
    return Snapshot(state: st, tooltip: "\(title)\n\(reportNote)\(sessNote)", openTarget: rm != nil ? report : brief, title: title, summary: act.summary, replyEvent: nil)
}

// MARK: - 뷰
//
// "말 없는 워커" (2026-09-03): 평소엔 글자가 없다. 상태는 마스코트 자체로 —
//   작업중(시동·답장 처리중 포함) = 눈 반사광 / 쉼(유휴·브리프 없음) = 눈 감음 /
//   컨펌 대기·논의 = 호박 테두리 발광 + 말풍선 / 사람 필요 = 적 발광 + 말풍선
// 글자(말풍선)는 사람이 행동해야 할 때와 엿보기(한 번 클릭, 3초)에만 뜬다. 이름은 툴팁, 분신은 숫자 배지.

var appController: WorkerController?
var peekUntil: Date?   // 엿보기 — 모든 워커가 말풍선을 잠시 보여준다
func alwaysBubbles() -> Bool { UserDefaults.standard.bool(forKey: "madang.bubbles") }   // 메뉴 "말풍선 항상 표시"

/// 브리프 H1은 "브리프 — 이름 (key) · 날짜 · 태스크명" 꼴 — 260pt에서 앞부분(이름·날짜)에 밀려
/// 정작 태스크명이 잘리므로, 이 패턴이면 마지막 " · " 뒤(태스크명)만 보여준다. 패턴이 안 맞으면 원문 그대로.
/// H1(`# `) 벗기기는 firstLine이 전담 — 여기선 다시 벗기지 않는다(2026-09-05 리뷰 결함 8, firstLine과 통일).
func displayTitle(_ raw: String) -> String {
    guard raw.hasPrefix("브리프 — "), let r = raw.range(of: " · ", options: .backwards) else { return raw }
    return String(raw[r.upperBound...])
}

/// 말풍선 폭 상한(기본 260pt, 컨테이너가 더 좁으면 그에 맞춤 — 결함 4)에 맞춰 잘라낸다.
/// 한글은 라틴보다 글리프가 넓어 글자수 대신 실측 폭으로 판단. "…" 자체의 폭도 상한에서 미리 빼야
/// 최종 문자열(자른 텍스트 + "…")이 상한을 넘지 않는다(2026-09-05 리뷰 결함 8).
func truncatedToWidth(_ s: String, font: NSFont, maxWidth: CGFloat) -> String {
    let attrs: [NSAttributedString.Key: Any] = [.font: font]
    guard (s as NSString).size(withAttributes: attrs).width > maxWidth else { return s }
    let ellipsisW = ("…" as NSString).size(withAttributes: attrs).width
    var t = s
    while t.count > 1, (t as NSString).size(withAttributes: attrs).width + ellipsisW > maxWidth {
        t.removeLast()
    }
    return t + "…"
}

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
        frame.size = NSSize(width: max(w, 44), height: ceil(text.size().height) + 10 + tail)   // 2~3줄 대응 — 높이는 실측 텍스트 블록 기준
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
        // draw(at:)는 여러 줄일 때 문단 정렬(.center)을 무시하고 왼쪽 정렬로 그린다 — draw(in:)으로
        // 폭을 지정해 그 안에서 정렬시킨다(2026-09-05 리뷰 결함 5).
        text.draw(in: NSRect(x: 0, y: tail + (body.height - ts.height) / 2 + 0.5, width: bounds.width, height: ts.height))
    }
}

final class WorkerView: NSView {
    let inst: Instance
    let emoji = NSTextField(labelWithString: "")   // SVG 없을 때 폴백
    let figure = NSImageView()
    let num = NSTextField(labelWithString: "")     // 분신 번호
    let bubble = BubbleView()
    var state: WorkerState = .resting(nil)
    var openTarget: URL?
    var title = ""             // 브리프 제목 — 말풍선 1번째 추가 줄
    var summary: String?       // lastSessionActivity 캐시 — 말풍선 2번째 추가 줄(hover 1.5초 뒤)
    var hoverSince: Date?
    var summaryRevealed = false
    var phase: CGFloat = .random(in: 0...6)
    var smileUntil: Date?
    var lastSeenReply: Date?        // 답장 처리중 미소를 1회만 트리거하기 위한 기준값
    var hasAppliedOnce = false       // 첫 apply()에서는 미소를 트리거하지 않는다(오래된 reply 오탐 방지)
    var themedDark = isDark()
    let figureBaseY: CGFloat = 18, figureH: CGFloat = 78

    init(_ inst: Instance) {
        self.inst = inst
        super.init(frame: NSRect(x: 0, y: 0, width: workerW, height: workerH))
        wantsLayer = true

        if mascotImage(inst.role.id) != nil {
            figure.imageScaling = .scaleProportionallyUpOrDown
            figure.frame = NSRect(x: 9, y: figureBaseY, width: workerW - 18, height: figureH)
            addSubview(figure)
        } else {
            emoji.font = .systemFont(ofSize: 46); emoji.alignment = .center
            emoji.stringValue = inst.role.emoji
            emoji.frame = NSRect(x: 0, y: figureBaseY, width: workerW, height: 60)
            addSubview(emoji)
        }
        figure.wantsLayer = true   // 상태 색은 실루엣 발광으로, 평소엔 부드러운 그림자 (테두리 없음)

        if !inst.suffix.isEmpty {
            num.font = .systemFont(ofSize: 9, weight: .bold); num.alignment = .center
            num.stringValue = inst.suffix
            num.wantsLayer = true; num.layer?.cornerRadius = 7
            num.frame = NSRect(x: workerW - 24, y: figureBaseY - 2, width: 14, height: 14)
            addSubview(num)
        }
        bubble.isHidden = true
        addSubview(bubble)
        retheme()
    }
    required init?(coder: NSCoder) { fatalError() }

    // 마우스를 올리면 그 워커만 말풍선 (클릭 없이 바로)
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil))
    }
    override func mouseEntered(with event: NSEvent) { hovered = true; hoverSince = Date(); summaryRevealed = false; refreshBubble() }
    override func mouseExited(with event: NSEvent) { hovered = false; hoverSince = nil; summaryRevealed = false; refreshBubble() }

    var variant: String {
        if smileUntil != nil { return "-smile" }
        switch state {
        case .resting:  return "-sleep"      // 잠
        case .working:  return "-work"       // 집중 — 눈이 커지고 눈동자에 자기 도형
        default:        return ""            // 깨어 있음 — 컨펌 대기·논의·사람 필요
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
        let font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        // 워커 1~2명 팀은 컨테이너 자체가 260pt보다 좁아 고정 상한만 쓰면 말풍선이 창 밖으로 잘린다 —
        // 컨테이너 폭에 맞춰 상한을 낮춘다(2026-09-05 리뷰 결함 4).
        let cap: CGFloat = 260 - 18
        let maxW: CGFloat = superview.map { min(cap, $0.bounds.width - 8) } ?? cap
        var lines = [state.label]
        // 상태 텍스트가 이미 말풍선에 있을 때(showBubble) 그 아래에 브리프 제목을 붙인다 — 기존 줄 유지
        if showBubble, !title.isEmpty { lines.append(truncatedToWidth(displayTitle(title), font: font, maxWidth: maxW)) }
        // 2번째 줄(마지막 산출 턴 요약)은 always-표시와 무관하게 실제 hover 1.5초 뒤에만 — 세션 매칭 없으면 생략
        if hovered, summaryRevealed, let s = summary { lines.append(truncatedToWidth(s, font: font, maxWidth: maxW)) }
        bubble.set(lines.joined(separator: "\n"), color: state.color ?? Palette.current.ink)
        // 여러 줄이 되면서 폭이 workerW를 넘어설 수 있다 — 가장자리 워커에서 창(=container) 밖으로 잘리지 않게 클램프
        var x = (workerW - bubble.frame.width) / 2
        if let containerW = superview?.bounds.width {
            x = min(max(x, -frame.origin.x), containerW - bubble.frame.width - frame.origin.x)
        }
        // 꼬리(말풍선 아랫변)를 워커 상단의 고정 위치에 붙이고 줄이 늘면 위로 자란다 — 패널에 이미
        // bubbleHeadroom만큼 여유 높이가 있어(전역 상수) workerH 위로 넘어가도 잘리지 않는다.
        // 예전엔 "workerH를 넘으면 아래로 다시 밀어내는" 오버플로 분기가 있어 3줄일 때 머리를 덮었다 —
        // 그 분기를 삭제하고 y를 상수로 고정한다(2026-09-05 리뷰 결함 3).
        let anchorY: CGFloat = workerH - 2 - (24 + bubble.tail)   // 기존 1줄 기준 정지 위치와 동일
        bubble.frame.origin = NSPoint(x: x, y: anchorY)
        bubble.isHidden = !showBubble
    }

    func apply(_ s: Snapshot) {
        let previous = state
        let changed = s.state != previous
        state = s.state
        openTarget = s.openTarget
        title = s.title
        summary = s.summary
        toolTip = "\(inst.role.name)\(inst.suffix) — \(s.state.label)\n\(s.tooltip)"
        if case .resting(nil) = s.state { alphaValue = 0.5 } else { alphaValue = 1.0 }   // "쉼"(브리프 없음)만 흐리게 — 유휴는 그대로
        setGlow(s.state.color)
        if themedDark != isDark() { retheme() } else if changed || smileUntil == nil { figure.image = mascotImage(inst.role.id, variant: variant); refreshBubble() }
        var wasResting = false
        if case .resting = previous { wasResting = true }
        if changed, s.state == .working, wasResting { spinOnce() }   // 시동 — 쉼(닫힌 눈)에서 작업중으로 깨어나는 순간만
        // 답장 처리중 → APPROVE 순간의 미소는 상태가 아니라 전이 애니메이션(2~3초)로만 남긴다(AC A).
        // hasAppliedOnce 가드: 앱을 막 띄웠을 때 이미 있던 오래된 reply로 오탐 미소하지 않게.
        if hasAppliedOnce, let rm = s.replyEvent, rm != lastSeenReply,
           let reply = s.openTarget, firstLine(reply).uppercased().hasPrefix("APPROVE") {
            smile()
        }
        lastSeenReply = s.replyEvent
        hasAppliedOnce = true
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
        if hovered, !summaryRevealed, let since = hoverSince, Date().timeIntervalSince(since) >= 1.5 {
            summaryRevealed = true
            refreshBubble()
        }
        let want = showBubble
        if bubble.isHidden == want { refreshBubble() }
    }

    // 컨펌 대기·논의 = 호박, 사람 필요 = 적으로 실루엣 가장자리가 빛난다. 정적 — 깜빡이지 않는다.
    func setGlow(_ color: NSColor?) {
        guard let l = figure.layer else { return }
        if let c = color {
            l.shadowColor = c.cgColor; l.shadowOpacity = 1; l.shadowRadius = 7; l.shadowOffset = .zero
        } else {
            // 평소: 테두리 없음(SVG는 실루엣만) — 바탕과 분리는 본체 반대색의 부드러운 그림자가 맡는다
            l.shadowColor = Palette.current.paper.cgColor; l.shadowOpacity = 0.45; l.shadowRadius = 4; l.shadowOffset = .zero
        }
    }

    // 시동: 쉼에서 깨어 일을 시작하는 순간 제자리에서 살짝 기울었다 돌아온다 (1회, 0.9초 — 한 바퀴는 튄다는 사용자 피드백)
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

    // 워커 박스 전체가 드래그 영역. 한 번 클릭(안 움직임) = 전원 엿보기 2.5초, 더블클릭 = 파일 열기
    override func hitTest(_ point: NSPoint) -> NSView? { frame.contains(point) ? self : nil }
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 { openFile(); return }
        let before = window?.frame.origin
        window?.performDrag(with: event)
        if before == window?.frame.origin { peekUntil = Date().addingTimeInterval(2.5) }   // 엿보기 2.5초 — 세 개 훑기엔 충분, 거슬리진 않는 길이
    }
    // 우클릭 = 메뉴 (상단바 아이콘이 넘쳐서 안 보일 때의 조작 경로)
    override func rightMouseDown(with event: NSEvent) {
        guard let c = appController else { return }
        NSMenu.popUpContextMenu(c.buildMenu(), with: event, for: self)
    }
    @objc func openFile() {
        if let u = openTarget { NSWorkspace.shared.open(u) }
    }
}

// MARK: - 메뉴바 아이콘 (도담 잉크 실루엣, 템플릿 18pt)

/// 도담(팀장) 원 얼굴을 18pt 템플릿 이미지로 — 라이트/다크 메뉴바에서 시스템이 자동 반전한다.
/// 잉크 실루엣 채움 + 눈 두 개 구멍(even-odd) — 말랑(~/dev/slime)과 같은 "흰 실루엣 + 눈 구멍" 문법.
/// 좌표는 make-mascots.py의 lead 얼굴(circle r=40 @ 120 캔버스, eye_y=62)과 같은 비율 감각을
/// 18pt로 옮기되, 눈 크기는 소형 아이콘 가독성을 위해 비율보다 키웠다(순수 비례 축소 시 1pt 미만이라 안 보임).
func mascotStatusIcon() -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size, flipped: false) { _ in
        let cx: CGFloat = 9, cy: CGFloat = 9.2, r: CGFloat = 7.6   // 지름 15.2pt, 가장자리 여백 1.4pt
        let eyeR: CGFloat = 1.6, eyeDX: CGFloat = 2.7, eyeDY: CGFloat = 0.6
        func eye(_ dx: CGFloat) -> NSBezierPath {
            NSBezierPath(ovalIn: NSRect(x: cx + dx - eyeR, y: cy + eyeDY - eyeR, width: eyeR * 2, height: eyeR * 2))
        }
        let face = NSBezierPath(ovalIn: NSRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        face.append(eye(-eyeDX)); face.append(eye(eyeDX))
        face.windingRule = .evenOdd
        NSColor.black.set()
        face.fill()
        return true
    }
    image.isTemplate = true
    return image
}

// MARK: - 컨트롤러

final class WorkerController: NSObject {
    let panel: NSPanel
    let container = NSView()
    var workers: [WorkerView] = []
    var lastStates: [String: WorkerState] = [:]
    var statusItem: NSStatusItem!
    let silent = ProcessInfo.processInfo.environment["MADANG_SILENT"] != nil

    override init() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: workerW, height: panelH),
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
            self?.workers.forEach { $0.tick() }
        }
        setupStatusItem()
    }

    func rebuild() {
        let insts = discoverInstances()
        if insts.map(\.key) == workers.map(\.inst.key) { refreshStates(); return }
        workers.forEach { $0.removeFromSuperview() }
        workers = insts.map(WorkerView.init)
        let w = CGFloat(workers.count) * workerW + 8
        let origin = panel.frame.origin
        panel.setContentSize(NSSize(width: w, height: panelH))
        panel.setFrameOrigin(origin)
        for (i, p) in workers.enumerated() {
            p.frame.origin = NSPoint(x: 4 + CGFloat(i) * workerW, y: 0)   // 바닥에 고정 — 위쪽 bubbleHeadroom이 말풍선 여유
            container.addSubview(p)
        }
        refreshStates()
    }

    func refresh() { rebuild() }

    func refreshStates() {
        for p in workers {
            let s = snapshot(p.inst)
            let prev = lastStates[p.inst.key]
            p.apply(s)
            if s.state.alert, prev != nil, prev != s.state, !silent {
                NSSound(named: NSSound.Name("Pop"))?.play()
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
        statusItem.button?.image = mascotStatusIcon()
        statusItem.menu = buildMenu()
    }
    @objc func setInk(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.representedObject as? String ?? "white", forKey: "madang.ink")
        workers.forEach { $0.retheme() }
        statusItem.menu = buildMenu()
    }
    @objc func toggleBubbles(_ sender: NSMenuItem) {
        UserDefaults.standard.set(!alwaysBubbles(), forKey: "madang.bubbles")
        workers.forEach { $0.refreshBubble() }
        statusItem.menu = buildMenu()
    }
    @objc func quit() { NSApp.terminate(nil) }
}

// MARK: - 실행

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let controller = WorkerController()
appController = controller
app.run()
