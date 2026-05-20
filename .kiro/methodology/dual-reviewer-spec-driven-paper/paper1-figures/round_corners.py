"""
Graphviz の splines=ortho が生成する SVG の L 字（90度の方向転換）を
小さな半径の二次ベジエ曲線に置き換えて、角を丸める後処理スクリプト。

使い方:
  python3 round_corners.py <入力 SVG> <出力 SVG> [半径]

設計:
- 各 path 要素の d 属性を読み、M / L コマンドの連続列を取り出す
- 連続する3点 P0 P1 P2 で「P0→P1 が水平／垂直」かつ「P1→P2 が直交」なら
  P1 を角として丸める
- 丸めの実装: P1 の手前で半径 r 分手前に L を打ち、P1 を制御点として
  P2 方向に半径 r 進んだ点へ Q（二次ベジエ）で描く
- C コマンド（既存の曲線）はそのまま保持
- スタイル属性 stroke-linejoin/stroke-linecap も round に
"""

import sys
import re
import xml.etree.ElementTree as ET
import math
from copy import deepcopy

DEFAULT_RADIUS = 6.0  # SVG 単位での角丸半径


def parse_path_d(d):
    """SVG path の d 属性をトークン列にする。
    対応: M, L, C, Z（およびそれらの小文字版は絶対化していない＝そのまま）
    """
    # コマンド文字と数値（負号や小数点を含む）を分解
    token_re = re.compile(r'[MLCZHVAmlczhva]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')
    return token_re.findall(d)


def segments_from_tokens(tokens):
    """トークン列を「コマンド+座標」のセグメントに分解。
    例: ['M','10','20','L','30','20','L','30','50','Z']
      → [('M',[(10,20)]), ('L',[(30,20)]), ('L',[(30,50)]), ('Z',[])]
    """
    segs = []
    i = 0
    while i < len(tokens):
        cmd = tokens[i]
        i += 1
        if cmd in ('M', 'L'):
            # 1座標
            x = float(tokens[i]); y = float(tokens[i+1]); i += 2
            segs.append((cmd, [(x, y)]))
        elif cmd == 'C':
            # 3座標 (制御点2つ + 終点)
            pts = []
            for _ in range(3):
                x = float(tokens[i]); y = float(tokens[i+1]); i += 2
                pts.append((x, y))
            segs.append((cmd, pts))
        elif cmd == 'Z':
            segs.append((cmd, []))
        else:
            # 未対応コマンドはスキップせず素通し（数値はそのまま読み飛ばす）
            # 簡略のため：未知コマンドが出たら処理中止
            return None
    return segs


def fmt(x):
    """SVG 数値の文字列化（小数点末尾ゼロを削る）"""
    s = f'{x:.3f}'
    if '.' in s:
        s = s.rstrip('0').rstrip('.')
    return s


def round_corners(segs, radius):
    """連続する L コマンドの間で 90 度の方向転換を丸める。
    M [Lx Ly]+ Z のような単純な polyline 系のみ対象。
    曲線が混ざる path は素通し。
    """
    # path のうち、L コマンドが連続している区間を見つける
    # 各 path は単一の M で始まり、その後 L が続くケースを想定
    if not segs:
        return segs
    if segs[0][0] != 'M':
        return segs
    # 全セグメントが M, L, Z の組み合わせか確認
    for cmd, _ in segs:
        if cmd not in ('M', 'L', 'Z'):
            return segs

    # 座標列を抽出（L の終点を順に並べる、Z は閉じる扱い）
    pts = [segs[0][1][0]]
    has_z = False
    for cmd, coords in segs[1:]:
        if cmd == 'L':
            pts.append(coords[0])
        elif cmd == 'Z':
            has_z = True

    n = len(pts)
    if n < 3:
        return segs

    # 各頂点 i（1 <= i <= n-2）について、P[i-1] -> P[i] -> P[i+1] が
    # 直交した方向転換ならば丸める
    new_pts = []  # 出力する path の座標群（コマンドつき）
    # コマンド列を作る
    out = []
    out.append(('M', [pts[0]]))
    for i in range(1, n):
        p_prev = pts[i-1]
        p_curr = pts[i]
        if i < n - 1 or has_z:
            # 次の点：閉路なら最初に戻る
            p_next = pts[i+1] if i < n - 1 else pts[0] if has_z else None
            if p_next is None:
                out.append(('L', [p_curr]))
                continue
            v1 = (p_curr[0] - p_prev[0], p_curr[1] - p_prev[1])
            v2 = (p_next[0] - p_curr[0], p_next[1] - p_curr[1])
            len1 = math.hypot(*v1); len2 = math.hypot(*v2)
            if len1 < 1e-6 or len2 < 1e-6:
                out.append(('L', [p_curr]))
                continue
            # 直交判定: 内積が概ね 0
            dot = (v1[0]*v2[0] + v1[1]*v2[1]) / (len1 * len2)
            if abs(dot) < 0.05:
                # 半径を min(len1, len2)/2 と DEFAULT_RADIUS の小さい方
                r = min(radius, len1 * 0.45, len2 * 0.45)
                if r > 0.5:
                    # 入り点：P_curr から P_prev 方向に r 進んだ点
                    enter = (
                        p_curr[0] - v1[0] / len1 * r,
                        p_curr[1] - v1[1] / len1 * r,
                    )
                    # 出る点：P_curr から P_next 方向に r 進んだ点
                    exit_pt = (
                        p_curr[0] + v2[0] / len2 * r,
                        p_curr[1] + v2[1] / len2 * r,
                    )
                    out.append(('L', [enter]))
                    out.append(('Q', [p_curr, exit_pt]))
                    continue
        out.append(('L', [p_curr]))

    if has_z:
        out.append(('Z', []))
    return out


def segs_to_d(segs):
    parts = []
    for cmd, coords in segs:
        parts.append(cmd)
        if cmd == 'Q':
            # Q cx,cy x,y
            parts.append(f'{fmt(coords[0][0])},{fmt(coords[0][1])}')
            parts.append(f'{fmt(coords[1][0])},{fmt(coords[1][1])}')
        else:
            for x, y in coords:
                parts.append(f'{fmt(x)},{fmt(y)}')
    return ' '.join(parts)


def process_svg(in_path, out_path, radius):
    ET.register_namespace('', 'http://www.w3.org/2000/svg')
    tree = ET.parse(in_path)
    root = tree.getroot()
    ns = {'svg': 'http://www.w3.org/2000/svg'}

    paths = root.findall('.//svg:path', ns)
    for p in paths:
        d = p.get('d', '')
        if not d:
            continue
        tokens = parse_path_d(d)
        if not tokens:
            continue
        segs = segments_from_tokens(tokens)
        if segs is None:
            continue
        new_segs = round_corners(segs, radius)
        if new_segs == segs:
            continue
        p.set('d', segs_to_d(new_segs))
        # 線の継ぎ目を round に
        style = p.get('style', '')
        if 'stroke-linejoin' not in style:
            style = (style + ';' if style else '') + 'stroke-linejoin:round;stroke-linecap:round'
        p.set('style', style)

    tree.write(out_path, xml_declaration=True, encoding='utf-8')


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('usage: round_corners.py <input.svg> <output.svg> [radius]')
        sys.exit(1)
    in_path = sys.argv[1]
    out_path = sys.argv[2]
    radius = float(sys.argv[3]) if len(sys.argv) > 3 else DEFAULT_RADIUS
    process_svg(in_path, out_path, radius)
    print(f'Rounded corners written to {out_path} (radius={radius})')
