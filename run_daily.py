#!/usr/bin/env python3
from __future__ import annotations

import argparse
from datetime import date as dt_date, datetime
from pathlib import Path
import shutil
import sys

BASE_DIR = Path(__file__).resolve().parent


def valid_date(value: str) -> str:
    try:
        datetime.strptime(value, '%Y-%m-%d')
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f'日期格式错误: {value}，应为 YYYY-MM-DD') from exc
    return value


def ensure_text(path: Path, content: str) -> None:
    if not path.exists():
        path.write_text(content, encoding='utf-8')


def build_research_template(day: str) -> str:
    return f"""谁在花钱｜每日花钱新闻日报
日期：{day}

一、今日要点
- 待补充

二、分项日报

【政府】
- 花钱主体：
- 金额：
- 领域：
- 事件：
- 对普通人的提示：

【国际政府与开发资金】
- 花钱主体：
- 金额：
- 领域：
- 事件：
- 对普通人的提示：

【投资机构】
- 花钱主体：
- 金额：
- 领域：
- 事件：
- 对普通人的提示：

【企业】
- 花钱主体：
- 金额：
- 领域：
- 事件：
- 对普通人的提示：

【富豪资本】
- 花钱主体：
- 金额：
- 领域：
- 事件：
- 对普通人的提示：

【平民消费】
- 花钱主体：
- 热门品类（至少3个）：
- 代表产品（至少3个）：
- 品类金额/增速：
- 昨日最火消费品牌（国内，至少3个）：
- 昨日最火消费品牌（国外，至少3个）：
- 事件：
- 对普通人的提示：

【高薪职位】
- 岗位方向（不限行业，至少覆盖3个行业）：
- 中国高薪岗位（岗位、月薪、币种、参考来源）：
- 国际高薪岗位（岗位、月薪、币种、参考来源）：
- 薪资区间与口径：
- 门槛：
- 为什么现在高薪：
- 普通人如何切入：

三、今日结论
- 待补充
"""


def build_publish_template(day: str) -> str:
    return f"""谁在花钱｜每日花钱新闻日报
{day}

今天，全球的大钱主要流向了：
- 待补充

政府
待补充

国际政府与开发资金
待补充

投资机构
待补充

企业
待补充

富豪资本
待补充

平民消费
待补充

高薪职位
待补充

今日结论
待补充
"""


def build_material_template(day: str) -> str:
    return f"""谁在花钱｜素材池
日期：{day}

把当天抓到的原始新闻、公告、链接、金额、备注先丢到这里。
建议格式：
- 分类：政府 / 国际政府与开发资金 / 投资机构 / 企业 / 富豪资本 / 平民消费
- 标题：
- 主体：
- 金额：
- 领域：
- 主来源：
- 交叉来源：
- 备注：

平民消费素材建议格式：
- 热门品类：
- 代表产品：
- 品类金额或增速：
- 昨日最火消费品牌（国内）：
- 昨日最火消费品牌（国外）：
- 价格带变化：
- 主来源：
- 交叉来源：
- 备注：

高薪职位素材建议格式：
- 岗位方向（不限行业，至少覆盖3个行业）：
- 典型岗位：
- 薪资区间：
- 币种：
- 月薪/年薪换算口径：
- 来源平台：
- 标准参考来源：
- 对普通人的切入要求：
- 风险提示：
"""


def build_prompt_template(day: str, day_dir: Path) -> str:
    research = day_dir / f'谁在花钱_日报_{day}.txt'
    publish = day_dir / f'谁在花钱_发布版_{day}.txt'
    material = day_dir / f'谁在花钱_素材池_{day}.txt'
    sources = BASE_DIR / '新闻源清单.txt'
    return f"""生成研究版：
请优先按照 {sources} 中的一级、二级、三级新闻源检索和筛选素材，并结合 {material} 中已有内容，整理成“谁在花钱”研究版日报，输出到 {research}。
要求保留：分类、金额、事件、对普通人的提示。
平民消费板块优先写“热门品类与代表产品的消费流向”，避免连续多天只写以旧换新或假期消费总额。
平民消费板块需补充“昨日最火中外消费品牌”（国内和国外各至少3个）。
高薪职位板块需分“中国”和“国际”两组输出；每个岗位必须标明薪资币种、月薪口径和标准参考来源，国际薪资如换算成人民币需同时保留原币种。
同一自然月内，已发布过且“主体+事件+金额”相同的新闻不得重复入选；如有重大更新（金额变化、交易落地、官方新公告）才可再次入选，并明确写出“更新点”。

生成发布版：
请基于研究版日报，再整理成一个适合直接发布的版本，输出到 {publish}。
要求去掉方法说明、采样、来源、审查、核验，只保留可直接发布的正文。
"""


def init_day(day: str) -> None:
    day_dir = BASE_DIR / day
    day_dir.mkdir(parents=True, exist_ok=True)

    ensure_text(day_dir / f'谁在花钱_素材池_{day}.txt', build_material_template(day))
    ensure_text(day_dir / f'谁在花钱_日报_{day}.txt', build_research_template(day))
    ensure_text(day_dir / f'谁在花钱_发布版_{day}.txt', build_publish_template(day))
    ensure_text(day_dir / '生成指令.txt', build_prompt_template(day, day_dir))

    latest = BASE_DIR / 'latest'
    if latest.exists() or latest.is_symlink():
        if latest.is_symlink() or latest.is_file():
            latest.unlink()
        else:
            shutil.rmtree(latest)
    latest.symlink_to(day_dir, target_is_directory=True)

    print(f'已初始化: {day_dir}')
    for file in sorted(day_dir.iterdir()):
        print(file.name)


def status(day: str | None) -> None:
    if day:
        targets = [BASE_DIR / day]
    else:
        targets = sorted([p for p in BASE_DIR.iterdir() if p.is_dir() and p.name != 'latest'])
    for target in targets:
        if not target.exists():
            print(f'不存在: {target}')
            continue
        print(target)
        for file in sorted(target.iterdir()):
            print(f'  - {file.name}')


def main() -> int:
    parser = argparse.ArgumentParser(description='谁在花钱日报半自动流程')
    subparsers = parser.add_subparsers(dest='command', required=True)

    init_parser = subparsers.add_parser('init', help='初始化某一天的日报目录')
    init_parser.add_argument('date', nargs='?', default=dt_date.today().isoformat(), type=valid_date)

    status_parser = subparsers.add_parser('status', help='查看目录状态')
    status_parser.add_argument('date', nargs='?', type=valid_date)

    args = parser.parse_args()

    BASE_DIR.mkdir(parents=True, exist_ok=True)

    if args.command == 'init':
        init_day(args.date)
        return 0
    if args.command == 'status':
        status(args.date)
        return 0
    return 1


if __name__ == '__main__':
    sys.exit(main())
