"""
週次レポート生成モジュール
株価データと会社情報をまとめたレポートを生成します
"""
import os
from datetime import datetime
from typing import List, Dict
import pandas as pd
import matplotlib
matplotlib.use('Agg')  # GUI不要のバックエンドを使用
import matplotlib.pyplot as plt
import seaborn as sns
from jinja2 import Template
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 日本語フォント設定
plt.rcParams['font.family'] = 'DejaVu Sans'
sns.set_style("whitegrid")


class ReportGenerator:
    """レポート生成クラス"""
    
    def __init__(self, output_dir: str = "./reports"):
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
        os.makedirs(os.path.join(output_dir, "charts"), exist_ok=True)
    
    def generate_html_report(self, stocks_data: List[Dict], price_changes: List[Dict]) -> str:
        """
        HTMLレポートを生成
        
        Args:
            stocks_data: 株価データのリスト
            price_changes: 価格変動データのリスト
            
        Returns:
            生成されたHTMLファイルのパス
        """
        # チャートを生成
        chart_paths = self._generate_charts(stocks_data)
        
        # レポート日時
        report_date = datetime.now().strftime("%Y年%m月%d日 %H:%M")
        
        # HTMLテンプレート
        html_template = """
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>週次株価レポート - {{ report_date }}</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }
        h2 {
            color: #34495e;
            margin-top: 30px;
            border-left: 4px solid #3498db;
            padding-left: 10px;
        }
        .stock-card {
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
            background-color: #fafafa;
        }
        .stock-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }
        .stock-name {
            font-size: 24px;
            font-weight: bold;
            color: #2c3e50;
        }
        .stock-ticker {
            font-size: 18px;
            color: #7f8c8d;
        }
        .price-info {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 15px 0;
        }
        .price-box {
            background-color: white;
            padding: 15px;
            border-radius: 5px;
            border-left: 4px solid #3498db;
        }
        .price-label {
            font-size: 12px;
            color: #7f8c8d;
            text-transform: uppercase;
        }
        .price-value {
            font-size: 20px;
            font-weight: bold;
            color: #2c3e50;
        }
        .change-positive {
            color: #27ae60;
        }
        .change-negative {
            color: #e74c3c;
        }
        .company-info {
            margin-top: 15px;
            padding: 15px;
            background-color: white;
            border-radius: 5px;
        }
        .info-row {
            display: flex;
            padding: 8px 0;
            border-bottom: 1px solid #ecf0f1;
        }
        .info-label {
            font-weight: bold;
            width: 150px;
            color: #34495e;
        }
        .info-value {
            color: #7f8c8d;
        }
        .chart-container {
            margin: 20px 0;
            text-align: center;
        }
        .chart-container img {
            max-width: 100%;
            height: auto;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .summary-table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        .summary-table th,
        .summary-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .summary-table th {
            background-color: #3498db;
            color: white;
        }
        .summary-table tr:hover {
            background-color: #f5f5f5;
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid #ecf0f1;
            text-align: center;
            color: #7f8c8d;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 週次株価レポート</h1>
        <p style="color: #7f8c8d;">レポート生成日時: {{ report_date }}</p>
        
        <h2>📈 サマリー</h2>
        <table class="summary-table">
            <thead>
                <tr>
                    <th>ティッカー</th>
                    <th>会社名</th>
                    <th>現在価格</th>
                    <th>1週間変動</th>
                    <th>1ヶ月変動</th>
                    <th>セクター</th>
                </tr>
            </thead>
            <tbody>
                {% for stock, changes in zip(stocks_data, price_changes) %}
                {% if 'error' not in stock %}
                <tr>
                    <td><strong>{{ stock.ticker }}</strong></td>
                    <td>{{ stock.company_name }}</td>
                    <td>{{ "%.2f"|format(stock.current_price) }} {{ stock.currency }}</td>
                    <td>
                        {% if 'week_change' in changes %}
                        <span class="{{ 'change-positive' if changes.week_change.percentage >= 0 else 'change-negative' }}">
                            {{ "%+.2f"|format(changes.week_change.percentage) }}%
                        </span>
                        {% else %}N/A{% endif %}
                    </td>
                    <td>
                        {% if 'month_change' in changes %}
                        <span class="{{ 'change-positive' if changes.month_change.percentage >= 0 else 'change-negative' }}">
                            {{ "%+.2f"|format(changes.month_change.percentage) }}%
                        </span>
                        {% else %}N/A{% endif %}
                    </td>
                    <td>{{ stock.sector }}</td>
                </tr>
                {% endif %}
                {% endfor %}
            </tbody>
        </table>
        
        {% for stock, changes in zip(stocks_data, price_changes) %}
        {% if 'error' not in stock %}
        <div class="stock-card">
            <div class="stock-header">
                <div>
                    <div class="stock-name">{{ stock.company_name }}</div>
                    <div class="stock-ticker">{{ stock.ticker }}</div>
                </div>
            </div>
            
            <div class="price-info">
                <div class="price-box">
                    <div class="price-label">現在価格</div>
                    <div class="price-value">{{ "%.2f"|format(stock.current_price) }} {{ stock.currency }}</div>
                </div>
                {% if 'week_change' in changes %}
                <div class="price-box">
                    <div class="price-label">1週間変動</div>
                    <div class="price-value {{ 'change-positive' if changes.week_change.percentage >= 0 else 'change-negative' }}">
                        {{ "%+.2f"|format(changes.week_change.percentage) }}%
                        ({{ "%+.2f"|format(changes.week_change.absolute) }} {{ stock.currency }})
                    </div>
                </div>
                {% endif %}
                {% if 'month_change' in changes %}
                <div class="price-box">
                    <div class="price-label">1ヶ月変動</div>
                    <div class="price-value {{ 'change-positive' if changes.month_change.percentage >= 0 else 'change-negative' }}">
                        {{ "%+.2f"|format(changes.month_change.percentage) }}%
                        ({{ "%+.2f"|format(changes.month_change.absolute) }} {{ stock.currency }})
                    </div>
                </div>
                {% endif %}
                {% if 'year_change' in changes %}
                <div class="price-box">
                    <div class="price-label">1年変動</div>
                    <div class="price-value {{ 'change-positive' if changes.year_change.percentage >= 0 else 'change-negative' }}">
                        {{ "%+.2f"|format(changes.year_change.percentage) }}%
                        ({{ "%+.2f"|format(changes.year_change.absolute) }} {{ stock.currency }})
                    </div>
                </div>
                {% endif %}
            </div>
            
            <div class="company-info">
                <h3 style="color: #34495e; margin-top: 0;">会社情報</h3>
                <div class="info-row">
                    <div class="info-label">セクター:</div>
                    <div class="info-value">{{ stock.sector }}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">業界:</div>
                    <div class="info-value">{{ stock.industry }}</div>
                </div>
                {% if stock.market_cap %}
                <div class="info-row">
                    <div class="info-label">時価総額:</div>
                    <div class="info-value">{{ "{:,.0f}".format(stock.market_cap) }} {{ stock.currency }}</div>
                </div>
                {% endif %}
                {% if stock.pe_ratio %}
                <div class="info-row">
                    <div class="info-label">PER:</div>
                    <div class="info-value">{{ "%.2f"|format(stock.pe_ratio) }}</div>
                </div>
                {% endif %}
                {% if stock.dividend_yield %}
                <div class="info-row">
                    <div class="info-label">配当利回り:</div>
                    <div class="info-value">{{ "%.2f"|format(stock.dividend_yield * 100) }}%</div>
                </div>
                {% endif %}
                {% if stock.website %}
                <div class="info-row">
                    <div class="info-label">ウェブサイト:</div>
                    <div class="info-value"><a href="{{ stock.website }}" target="_blank">{{ stock.website }}</a></div>
                </div>
                {% endif %}
                {% if stock.description and stock.description != 'N/A' %}
                <div class="info-row" style="flex-direction: column;">
                    <div class="info-label" style="margin-bottom: 5px;">会社概要:</div>
                    <div class="info-value">{{ stock.description[:500] }}{% if stock.description|length > 500 %}...{% endif %}</div>
                </div>
                {% endif %}
            </div>
            
            {% if stock.ticker in chart_paths %}
            <div class="chart-container">
                <h3 style="color: #34495e;">価格推移チャート</h3>
                <img src="{{ chart_paths[stock.ticker] }}" alt="{{ stock.ticker }} チャート">
            </div>
            {% endif %}
        </div>
        {% endif %}
        {% endfor %}
        
        <div class="footer">
            <p>このレポートは自動生成されました。</p>
            <p>投資判断は自己責任でお願いいたします。</p>
        </div>
    </div>
</body>
</html>
        """
        
        template = Template(html_template)
        html_content = template.render(
            stocks_data=stocks_data,
            price_changes=price_changes,
            report_date=report_date,
            chart_paths=chart_paths,
            zip=zip
        )
        
        # HTMLファイルを保存
        filename = f"stock_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.html"
        filepath = os.path.join(self.output_dir, filename)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        logger.info(f"HTMLレポートを生成しました: {filepath}")
        return filepath
    
    def _generate_charts(self, stocks_data: List[Dict]) -> Dict[str, str]:
        """
        各株の価格推移チャートを生成
        
        Args:
            stocks_data: 株価データのリスト
            
        Returns:
            チャートファイルパスの辞書（ティッカー -> パス）
        """
        chart_paths = {}
        
        for stock_data in stocks_data:
            if 'error' in stock_data or stock_data.get('ticker') is None:
                continue
            
            ticker = stock_data['ticker']
            yearly_data = stock_data.get('yearly_data')
            
            if yearly_data is None or yearly_data.empty:
                continue
            
            try:
                plt.figure(figsize=(12, 6))
                plt.plot(yearly_data.index, yearly_data['Close'], linewidth=2, color='#3498db')
                plt.fill_between(yearly_data.index, yearly_data['Close'], alpha=0.3, color='#3498db')
                company_name = stock_data.get("company_name", ticker)
                plt.title(f'{company_name} ({ticker}) - 1 Year Price Trend', 
                         fontsize=14, fontweight='bold', pad=20)
                plt.xlabel('Date', fontsize=12)
                plt.ylabel('Price', fontsize=12)
                plt.grid(True, alpha=0.3)
                plt.xticks(rotation=45)
                plt.tight_layout()
                
                chart_filename = f"{ticker}_chart_{datetime.now().strftime('%Y%m%d')}.png"
                chart_path = os.path.join(self.output_dir, "charts", chart_filename)
                plt.savefig(chart_path, dpi=150, bbox_inches='tight')
                plt.close()
                
                # HTMLから相対パスで参照できるように
                chart_paths[ticker] = f"charts/{chart_filename}"
                
            except Exception as e:
                logger.error(f"{ticker} のチャート生成中にエラーが発生しました: {str(e)}")
        
        return chart_paths
