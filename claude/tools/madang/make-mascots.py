#!/usr/bin/env python3
"""마스코트 SVG 생성기 — claude/assets/mascots/ 를 통째로 다시 만든다.

규칙(BRANDING.md · plans/brand-strategy-2026-09-03.md §6):
  본체 한 색 + 시그니처 슬롯 하나에만 역할 색 · 얼굴은 점 2개 + 선 1개, 눈은 몸통 중심선
  테두리(halo) 없음 (2026-09-04 사용자 결정 — 분리는 펫 쪽 부드러운 그림자가 맡는다)
변형: rest · smile(승인 1회) · sleep(유휴·휴식) · work(작업중 — 눈이 커지고 눈동자에 자기 도형)
색: light(본체 잉크 #1E2430, 눈 종이색) / dark(@dark, 본체 순백 #FFFFFF, 눈 잉크)
"""
import os, sys

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assets', 'mascots')
THEMES = {
    '':      dict(body='#1E2430', eye='#F5F7F8', acc={'solver': '#B8563F', 'builder': '#7A6FA8', 'sketcher': '#3E8E8A', 'narrator': '#C09A2B'}),
    '@dark': dict(body='#FFFFFF', eye='#1E2430', acc={'solver': '#D8836C', 'builder': '#A79DD1', 'sketcher': '#6DBDB8', 'narrator': '#E0BE5A'}),
}
BODY = {
    'lead':     ['<circle cx="60" cy="64" r="40"/>'],
    'solver':   ['<path d="M60 10 L104 102 L16 102 Z" stroke-width="8" stroke-linejoin="round"/>'],
    'builder':  ['<ellipse cx="60" cy="74" rx="44" ry="22"/>', '<circle cx="60" cy="54" r="24"/>', '<circle cx="35" cy="63" r="20"/>', '<circle cx="86" cy="62" r="19"/>'],
    'sketcher': ['<rect x="22" y="34" width="76" height="68" rx="8"/>'],
    'narrator': ['<rect x="16" y="30" width="92" height="58" rx="29"/>'],
}
SLOT = {
    'lead': [],
    'solver':   ['<path d="M60 8 L70 30 L50 30 Z"/>'],
    'builder':  ['<circle cx="110" cy="100" r="8"/>'],
    'sketcher': ['<rect x="22" y="22" width="34" height="18" rx="5"/>'],
    'narrator': ['<path d="M38 80 L26 108 L60 84 Z"/>'],
}
EYE_Y = {'lead': 62, 'solver': 82, 'builder': 69, 'sketcher': 66, 'narrator': 59}
LX, RX, GAP_MOUTH = 49, 73, 14


def fill(shapes, c):
    return ''.join(s.replace('/>', f' fill="{c}"' + (f' stroke="{c}"' if 'stroke-width' in s else '') + '/>') for s in shapes)


def pupil(id, cx, cy, c):
    """작업중 눈동자 — 자기 도형. 눈 반지름 6.5 안에 들어가는 크기."""
    if id == 'solver':
        return f'<path d="M{cx} {cy-4.2} L{cx+3.8} {cy+2.6} L{cx-3.8} {cy+2.6} Z" fill="{c}"/>'
    if id == 'builder':
        return (f'<circle cx="{cx}" cy="{cy-1}" r="2.6" fill="{c}"/><circle cx="{cx-2.6}" cy="{cy+0.6}" r="2.1" fill="{c}"/>'
                f'<circle cx="{cx+2.6}" cy="{cy+0.6}" r="2.1" fill="{c}"/><rect x="{cx-4}" y="{cy+0.6}" width="8" height="2.6" rx="1.3" fill="{c}"/>')
    if id == 'sketcher':
        return f'<rect x="{cx-3.4}" y="{cy-3.4}" width="6.8" height="6.8" rx="1.2" fill="{c}"/>'
    if id == 'narrator':
        return f'<rect x="{cx-4}" y="{cy-3.2}" width="8" height="5.4" rx="2.7" fill="{c}"/><path d="M{cx-2} {cy+1.8} L{cx-3.2} {cy+4.4} L{cx+0.4} {cy+2.2} Z" fill="{c}"/>'
    return f'<circle cx="{cx}" cy="{cy}" r="3.2" fill="{c}"/>'   # lead: 원


def face(id, variant, eye, body):
    y = EYE_Y[id]; my = y + GAP_MOUTH
    if variant == 'sleep':
        e = f'<path d="M{LX-4} {y}h8M{RX-4} {y}h8" stroke="{eye}" stroke-width="3" stroke-linecap="round"/>'
    elif variant == 'work':
        e = (f'<circle cx="{LX}" cy="{y}" r="6.5" fill="{eye}"/><circle cx="{RX}" cy="{y}" r="6.5" fill="{eye}"/>'
             + pupil(id, LX, y, body) + pupil(id, RX, y, body))
    else:
        e = f'<circle cx="{LX}" cy="{y}" r="4" fill="{eye}"/><circle cx="{RX}" cy="{y}" r="4" fill="{eye}"/>'
    if variant == 'smile':
        m = f'<path d="M{LX+4} {my-2}q7 6 14 0" stroke="{eye}" stroke-width="3" stroke-linecap="round" fill="none"/>'
    else:
        m = f'<path d="M{LX+5} {my}h12" stroke="{eye}" stroke-width="3" stroke-linecap="round"/>'
    return e + m


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.endswith('.svg'):
            os.remove(os.path.join(OUT, f))
    n = 0
    for suf, t in THEMES.items():
        for id in BODY:
            for v in ('rest', 'smile', 'sleep', 'work'):
                acc = t['acc'].get(id, t['body'])
                svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120">'
                       f'<!-- madang mascot: {id} {v} {"dark" if suf else "light"} · CC BY 4.0 · make-mascots.py -->'
                       f'<g>{fill(BODY[id], t["body"])}</g><g>{fill(SLOT[id], acc)}</g>{face(id, v, t["eye"], t["body"])}</svg>')
                name = f'{id}{"" if v == "rest" else "-" + v}{suf}.svg'
                open(os.path.join(OUT, name), 'w').write(svg); n += 1
    print(f'{n} files → {os.path.relpath(OUT)}')


if __name__ == '__main__':
    main()
