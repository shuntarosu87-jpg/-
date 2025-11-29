"""
株価監視システム - メインスクリプト
週次レポートを自動生成します
"""
import yaml
import schedule
import time
import logging
from datetime import datetime
from stock_data_fetcher import StockDataFetcher
from report_generator import ReportGenerator

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def load_config(config_path: str = "config.yaml") -> dict:
    """設定ファイルを読み込む"""
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
        return config
    except FileNotFoundError:
        logger.error(f"設定ファイルが見つかりません: {config_path}")
        raise
    except yaml.YAMLError as e:
        logger.error(f"設定ファイルの読み込みエラー: {e}")
        raise


def generate_weekly_report():
    """週次レポートを生成する関数"""
    logger.info("週次レポートの生成を開始します...")
    
    try:
        # 設定を読み込む
        config = load_config()
        watchlist = config.get('watchlist', [])
        report_config = config.get('report', {})
        output_dir = report_config.get('output_dir', './reports')
        
        if not watchlist:
            logger.warning("ウォッチリストが空です。設定ファイルを確認してください。")
            return
        
        # 株価データを取得
        fetcher = StockDataFetcher()
        logger.info(f"{len(watchlist)}件の株価データを取得中...")
        stocks_data = fetcher.get_multiple_stocks(watchlist)
        
        # 価格変動を計算
        price_changes = []
        for stock_data in stocks_data:
            if 'error' not in stock_data:
                changes = fetcher.calculate_price_change(stock_data)
                price_changes.append(changes)
            else:
                price_changes.append({})
        
        # レポートを生成
        generator = ReportGenerator(output_dir=output_dir)
        report_format = report_config.get('format', 'html')
        
        if report_format == 'html':
            report_path = generator.generate_html_report(stocks_data, price_changes)
            logger.info(f"レポートが生成されました: {report_path}")
        else:
            logger.warning(f"未対応のレポート形式です: {report_format}")
        
        # サマリーをログに出力
        logger.info("=" * 60)
        logger.info("レポートサマリー")
        logger.info("=" * 60)
        for stock_data, changes in zip(stocks_data, price_changes):
            if 'error' not in stock_data:
                ticker = stock_data['ticker']
                company_name = stock_data.get('company_name', 'N/A')
                current_price = stock_data.get('current_price', 'N/A')
                
                week_change = changes.get('week_change', {})
                week_pct = week_change.get('percentage', None)
                
                logger.info(f"{ticker} ({company_name}): {current_price}")
                if week_pct is not None:
                    logger.info(f"  1週間変動: {week_pct:+.2f}%")
        logger.info("=" * 60)
        
    except Exception as e:
        logger.error(f"レポート生成中にエラーが発生しました: {str(e)}", exc_info=True)


def run_scheduler():
    """スケジューラーを実行"""
    config = load_config()
    schedule_config = config.get('schedule', {})
    
    day_of_week = schedule_config.get('day_of_week', 'monday')
    time_str = schedule_config.get('time', '09:00')
    
    # スケジュールを設定
    if day_of_week == 'monday':
        schedule.every().monday.at(time_str).do(generate_weekly_report)
    elif day_of_week == 'tuesday':
        schedule.every().tuesday.at(time_str).do(generate_weekly_report)
    elif day_of_week == 'wednesday':
        schedule.every().wednesday.at(time_str).do(generate_weekly_report)
    elif day_of_week == 'thursday':
        schedule.every().thursday.at(time_str).do(generate_weekly_report)
    elif day_of_week == 'friday':
        schedule.every().friday.at(time_str).do(generate_weekly_report)
    elif day_of_week == 'saturday':
        schedule.every().saturday.at(time_str).do(generate_weekly_report)
    elif day_of_week == 'sunday':
        schedule.every().sunday.at(time_str).do(generate_weekly_report)
    
    logger.info(f"スケジューラーを設定しました: 毎週{day_of_week}の{time_str}にレポートを生成します")
    logger.info("スケジューラーを開始します... (Ctrl+Cで停止)")
    
    # スケジューラーを実行
    try:
        while True:
            schedule.run_pending()
            time.sleep(60)  # 1分ごとにチェック
    except KeyboardInterrupt:
        logger.info("スケジューラーを停止しました")


if __name__ == "__main__":
    import sys
    
    # コマンドライン引数で動作を切り替え
    if len(sys.argv) > 1 and sys.argv[1] == "--now":
        # 即座にレポートを生成
        generate_weekly_report()
    else:
        # スケジューラーを実行
        run_scheduler()
