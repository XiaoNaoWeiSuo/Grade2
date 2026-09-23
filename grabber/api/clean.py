# -*- coding: utf-8 -*-
"""数据清洗层:HTML → 结构化数据(原则:宁重复勿缺)

能力:
    parse_tables(html)    全部表格(含嵌套表);每单元格捕获
                          {text, attrs, links, images, span, colspan, rowspan}
                          rowspan/colspan 网格展开,占位继承源值并打 span 标记
    table_records(table)  表格 → dict 记录列表:表头命名 + _links + 数值化列
    kv_tables(html)       多张 KV 信息表(学籍/计划完成头部),按 darkColumn
                          分组行/表格前置标题(bold div/h1-h4/caption)分 section
    week_parse(bits)      周次位串 → {raw, digest, list, count, total}
    num(s)                文本 → 数值,失败回退原文(不丢信息)
    clean_ws(s)           压缩空白(含 &nbsp;/\xa0)
"""
import re
from html import unescape
from html.parser import HTMLParser

_HEADING_TAGS = ("h1", "h2", "h3", "h4", "legend")

# 需要数值化的列名(成绩/学分等)
_NUM_COL = re.compile(r"学分|绩点|成绩|分数|人数|上限|座位|序号|最终")


def clean_ws(s: str) -> str:
    if not s:
        return ""
    return re.sub(r"\s+", " ", s.replace("\xa0", " ")).strip()


def strip_all(s: str) -> str:
    """去标签 + 解码实体 + 压缩空白(兜底工具)。"""
    if not s:
        return ""
    s = unescape(re.sub(r"<[^>]*>", " ", s.replace("&nbsp;", " ")))
    return clean_ws(s)


def num(s):
    """整串为数字(可带小数)才数值化;否则原样返回(时间'14:00~15:50'等不误伤)。"""
    s = clean_ws(str(s or ""))
    if not s:
        return None
    if not re.fullmatch(r"-?\d+(?:\.\d+)?", s):
        return s
    v = float(s)
    return int(v) if v.is_integer() else v


def _int_or(s, default: int = 1) -> int:
    try:
        return max(1, int(str(s or "").strip()))
    except (TypeError, ValueError):
        return default


def week_parse(bits: str) -> dict:
    """周次位串('0111100…')→ 摘要/列表/数量。"""
    bits = bits or ""
    if len(bits) >= 20:
        # 长江大学教务系统 (URP) 53 位学年周次位串：索引 0 为占位符，index i 对应第 i 周
        weeks = [i for i in range(1, len(bits)) if bits[i] == "1"]
        total = len(bits) - 1
    else:
        weeks = [i + 1 for i, ch in enumerate(bits) if ch == "1"]
        total = len(bits)
    return {"raw": bits, "digest": _digest(weeks), "list": weeks,
            "count": len(weeks), "total": total}


def _digest(weeks: list) -> str:
    if not weeks:
        return ""
    wset = set(weeks)
    runs = []
    i = 0
    while i < len(weeks):
        # 1) 连续周（步长 1）
        j = i
        while j + 1 < len(weeks) and weeks[j + 1] == weeks[j] + 1:
            j += 1
        if j > i:
            runs.append(f"{weeks[i]}-{weeks[j]}")
            i = j + 1
            continue

        # 2) 单双周（步长 2，后续元素不能是连续周的起点）
        k = i
        while (k + 1 < len(weeks) and
               weeks[k + 1] == weeks[k] + 2 and
               (weeks[k + 1] + 1) not in wset):
            k += 1
        if k > i:
            prefix = "双" if weeks[i] % 2 == 0 else "单"
            runs.append(f"{prefix}{weeks[i]}-{weeks[k]}")
            i = k + 1
            continue

        # 3) 单周
        runs.append(str(weeks[i]))
        i += 1
    return ",".join(runs)


# ----------------------------------------------------------------------------
# 表格流式挖掘器(标准库 HTMLParser,容错优于正则配平)
# ----------------------------------------------------------------------------
class TableMiner(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.tables = []
        self._tstack = []      # 嵌套表栈(外层壳表 → 内层数据表)
        self._cell = None
        self._link = None
        self._caption = None
        self._heading = None   # [tag, [chunks]] 待关联到下一张表的前置标题

    # ---- 开始标签
    def handle_starttag(self, tag, attrs):
        a = {k: (v or "") for k, v in attrs}
        if tag == "table":
            title = ""
            if self._heading is not None:      # 消费前置标题
                title = clean_ws("".join(self._heading[1]))
                self._heading = None
            self._tstack.append({
                "id": a.get("id", ""), "class": a.get("class", ""),
                "title": title, "caption": "",
                "header_rows": [], "rows": [],
                "_spans": {}, "_row": None, "_col": 0, "_thead": False,
            })
            return
        if not self._tstack:                    # 表外:只关心标题
            if tag in _HEADING_TAGS:
                self._heading = [tag, []]
            elif tag == "div" and "font-weight:bold" in a.get("style", "").replace(" ", ""):
                self._heading = ["div", []]
            return
        t = self._tstack[-1]
        if tag == "tr":
            self._open_row(t)
        elif tag in ("td", "th"):
            self._open_cell(t, tag, a)
        elif tag == "caption":
            self._caption = []
        elif tag == "thead":
            t["_thead"] = True
        elif tag == "tbody":
            t["_thead"] = False
        elif tag == "a" and self._cell is not None:
            self._link = {"href": a.get("href", ""), "text": ""}
        elif tag == "img" and self._cell is not None:
            self._cell.setdefault("images", []).append({
                "src": a.get("src", ""), "alt": a.get("alt", ""),
                "title": a.get("title", "")})

    # ---- 结束标签
    def handle_endtag(self, tag):
        if tag == "table" and self._tstack:
            self._close_table()
            return
        if not self._tstack:
            return
        t = self._tstack[-1]
        if tag in ("td", "th"):
            self._close_cell(t)
        elif tag == "tr":
            self._close_row(t)
        elif tag in ("thead",):
            t["_thead"] = False
        elif tag == "caption" and self._caption is not None:
            t["caption"] = clean_ws("".join(self._caption))
            self._caption = None
        elif tag == "a" and self._link is not None:
            if self._cell is not None:
                self._cell["links"].append(self._link)
            self._link = None

    def handle_data(self, data):
        if self._caption is not None:
            self._caption.append(data)
        if self._link is not None:
            self._link["text"] += data
        if self._cell is not None:
            self._cell["text"] += data
        if self._heading is not None:
            self._heading[1].append(data)

    # ---- 行/单元格/表格收口
    def _open_row(self, t):
        self._close_cell(t)
        self._close_row(t)
        row = []
        t["_row"] = row
        col = 0
        spans = t["_spans"]                    # 跨行占位:继承源值并打标
        while col in spans:
            rem, cell = spans[col]
            row.append({**cell, "span": "row"})
            if rem - 1 <= 0:
                del spans[col]
            else:
                spans[col] = [rem - 1, cell]
            col += 1
        t["_col"] = col

    def _close_row(self, t):
        row = t.pop("_row", None)
        if row is None:
            return
        t["_col"] = 0
        if any(c["text"] for c in row):
            (t["header_rows"] if t["_thead"] else t["rows"]).append(row)

    def _open_cell(self, t, tag, a):
        self._close_cell(t)
        if t["_row"] is None:
            self._open_row(t)
        self._cell = {"tag": tag, "attrs": a, "text": "", "links": [],
                      "span": None,
                      "colspan": _int_or(a.get("colspan")),
                      "rowspan": _int_or(a.get("rowspan"))}

    def _close_cell(self, t):
        cell, self._cell = self._cell, None
        if cell is None:
            return
        row = t.get("_row")
        if row is None:
            return
        cell["text"] = clean_ws(cell["text"])
        row.append(cell)
        for _ in range(cell["colspan"] - 1):    # 跨列占位
            row.append({**cell, "span": "col"})
        if cell["rowspan"] > 1:                 # 登记跨行
            for k in range(cell["colspan"]):
                t["_spans"][t["_col"] + k] = [cell["rowspan"] - 1, cell]
        t["_col"] += cell["colspan"]

    def _close_table(self):
        t = self._tstack.pop()
        self._close_cell(t)
        self._close_row(t)
        self.tables.append({
            "id": t["id"], "class": t["class"], "title": t["title"],
            "caption": t["caption"], "header_rows": t["header_rows"],
            "headers": [c["text"] for c in t["header_rows"][0]] if t["header_rows"] else [],
            "rows": t["rows"], "n_rows": len(t["rows"]),
            "n_cols": max((len(r) for r in t["header_rows"] + t["rows"]), default=0),
            "empty": not t["rows"] and not t["header_rows"],
        })


def parse_tables(html: str) -> list:
    """提取页面全部表格(嵌套表独立产出,顺序=收口顺序)。"""
    if not html:
        return []
    miner = TableMiner()
    miner.feed(html)
    miner.close()
    return [t for t in miner.tables if not t["empty"]]


def pick_table(tables: list, class_kw: str = "", has_header: bool = False,
               title_kw: str = ""):
    """按 class 关键字/表头/前置标题挑选表格。"""
    for t in tables:
        if class_kw and class_kw not in t["class"]:
            continue
        if has_header and not t["headers"]:
            continue
        if title_kw and title_kw not in (t["title"] + t["caption"]):
            continue
        return t
    return None


def table_records(table: dict, header_row: int = None, autonum: bool = True) -> list:
    """表格 → 记录列表。

    - 表头:thead 首行;无 thead 时可用 header_row 指定数据首行为表头
    - 值:单元格纯文本;列名命中 学分/绩点/成绩 等自动数值化
    - 单元格链接 → 记录级 "_links": [{col, href, text}]
    - 行内仅一个非空单元格 → 分组行 {"_group": 文本}
    """
    if not table:
        return []
    headers = list(table["headers"])
    rows = list(table["rows"])
    if not headers and header_row is not None and rows and 0 <= header_row < len(rows):
        headers = [c["text"] for c in rows[header_row]]
        rows = rows[header_row + 1:]
    # 双行表头:第二行的子表头(如 1-8 学期数字)并入重复列名
    hr_rows = table.get("header_rows") or []
    sub = [c["text"] for c in hr_rows[1]] if len(hr_rows) > 1 else []
    records = []
    for row in rows:
        real = [c for c in row if not c["span"]]      # 排除 rowspan/colspan 占位
        real_texts = [c["text"] for c in real if c["text"]]
        head = row[0] if row else None
        if head and head["text"] and head["colspan"] >= 2:
            # 分组头行:跨列组名(其后可能带组级汇总,如 必修小计学分)
            d = {"_group": head["text"]}
            col = 0
            for c in row:
                if c is head:
                    col += c["colspan"]
                    continue
                if c["span"]:
                    col += 1
                    continue
                key = headers[col] if col < len(headers) and headers[col] else f"col{col + 1}"
                if c["text"]:
                    d[key] = num(c["text"]) if (autonum and _NUM_COL.search(key)) else c["text"]
                col += c["colspan"]
            records.append(d)
            continue
        if len(real) == 1 and real_texts:             # 唯一真实单元格 → 纯分组行
            records.append({"_group": real_texts[0]})
            continue
        d = {}
        for i, c in enumerate(row):
            key = headers[i] if i < len(headers) and headers[i] else f"col{i + 1}"
            if key in d:                       # 展开产生的重复列名 → 并子表头/加序号
                s = sub[i].strip() if i < len(sub) else ""
                key = f"{key}{s}" if s else f"{key}#{i + 1}"
            d[key] = num(c["text"]) if (autonum and _NUM_COL.search(key)) else c["text"]
        links = []
        for i, c in enumerate(row):
            col = headers[i] if i < len(headers) and headers[i] else f"col{i + 1}"
            links += [dict(l, col=col) for l in c["links"] if l.get("href")]
        if links:
            d["_links"] = links
        images = [img for c in row for img in c.get("images", []) if img.get("src")]
        if images:
            d["_images"] = images
        records.append(d)
    return records


def kv_tables(html: str) -> list:
    """页面全部 KV 信息表 → [{"section": 名称, "kv": {…}}, …]

    - section 来源:表格前置标题(bold div/h*)、caption、表内 darkColumn 分组行
    - 键:以冒号结尾的单元格;值:其后相邻单元格文本
    - 单元格内图片(如学籍照片)→ kv["照片"] = src
    """
    out = []
    for t in parse_tables(html):
        section, kv = t["title"] or t["caption"] or "", {}
        for row in t["header_rows"] + t["rows"]:
            real = [c for c in row if not c["span"]]
            real_texts = [c["text"] for c in real if c["text"]]
            first = real[0] if real else None
            if len(real) == 1 and first and "darkColumn" in first["attrs"].get("class", ""):
                if kv:
                    out.append({"section": section or "(未命名)", "kv": kv})
                    kv = {}
                section = real_texts[0] if real_texts else section
                continue
            i = 0
            while i < len(row) - 1:
                k = row[i]["text"]
                if k and k.rstrip().endswith((":", "：")):
                    v = row[i + 1]
                    key = k.rstrip(":： ").strip()
                    kv.setdefault(key, v["text"])
                    for l in v["links"]:
                        if l.get("href"):
                            kv.setdefault(f"{key}_链接", l["href"])
                    i += 2
                else:
                    i += 1
            # 行内图片(如学籍照片)统一捕获,不遗漏行尾单元格
            for c in row:
                for img in c.get("images", []):
                    if img.get("src"):
                        kv.setdefault("照片", img["src"])
        if kv:
            out.append({"section": section or "(未命名)", "kv": kv})
    return out
