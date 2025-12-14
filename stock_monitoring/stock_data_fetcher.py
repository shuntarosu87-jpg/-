"""
株価データ取得モジュール
yfinanceを使用して株価データを取得します
"""
import yfinance as yf
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class StockDataFetcher:
    """株価データを取得するクラス"""
    
    def __init__(self):
        self.cache = {}
    
    def get_stock_info(self, ticker: str) -> Dict:
        """
        指定されたティッカーシンボルの会社情報と現在の株価を取得
        
        Args:
            ticker: ティッカーシンボル（例: AAPL）
            
        Returns:
            会社情報と株価データの辞書
        """
        try:
            stock = yf.Ticker(ticker)
            info = stock.info
            
            # 現在の株価データを取得
            current_data = stock.history(period="1d")
            current_price = current_data['Close'].iloc[-1] if not current_data.empty else None
            
            # 過去1週間のデータを取得
            weekly_data = stock.history(period="5d")
            
            # 過去1ヶ月のデータを取得
            monthly_data = stock.history(period="1mo")
            
            # 過去1年のデータを取得
            yearly_data = stock.history(period="1y")
            
            result = {
                'ticker': ticker,
                'company_name': info.get('longName', info.get('shortName', 'N/A')),
                'sector': info.get('sector', 'N/A'),
                'industry': info.get('industry', 'N/A'),
                'current_price': float(current_price) if current_price else None,
                'currency': info.get('currency', 'USD'),
                'market_cap': info.get('marketCap', None),
                'pe_ratio': info.get('trailingPE', None),
                'dividend_yield': info.get('dividendYield', None),
                '52_week_high': info.get('fiftyTwoWeekHigh', None),
                '52_week_low': info.get('fiftyTwoWeekLow', None),
                'description': info.get('longBusinessSummary', 'N/A'),
                'website': info.get('website', 'N/A'),
                'employees': info.get('fullTimeEmployees', None),
                'current_data': current_data,
                'weekly_data': weekly_data,
                'monthly_data': monthly_data,
                'yearly_data': yearly_data,
                'fetched_at': datetime.now().isoformat()
            }
            
            logger.info(f"{ticker} のデータを取得しました")
            return result
            
        except Exception as e:
            logger.error(f"{ticker} のデータ取得中にエラーが発生しました: {str(e)}")
            return {
                'ticker': ticker,
                'error': str(e),
                'fetched_at': datetime.now().isoformat()
            }
    
    def get_multiple_stocks(self, tickers: List[str]) -> List[Dict]:
        """
        複数のティッカーシンボルのデータを取得
        
        Args:
            tickers: ティッカーシンボルのリスト
            
        Returns:
            各株の情報のリスト
        """
        results = []
        for ticker in tickers:
            stock_info = self.get_stock_info(ticker)
            results.append(stock_info)
        return results
    
    def calculate_price_change(self, stock_data: Dict) -> Dict:
        """
        価格変動を計算
        
        Args:
            stock_data: get_stock_info()で取得したデータ
            
        Returns:
            価格変動情報の辞書
        """
        if 'error' in stock_data or not stock_data.get('current_price'):
            return {}
        
        current_price = stock_data['current_price']
        weekly_data = stock_data.get('weekly_data')
        monthly_data = stock_data.get('monthly_data')
        yearly_data = stock_data.get('yearly_data')
        
        changes = {}
        
        # 1週間の変動
        if weekly_data is not None and not weekly_data.empty:
            week_ago_price = weekly_data['Close'].iloc[0]
            changes['week_change'] = {
                'absolute': current_price - week_ago_price,
                'percentage': ((current_price - week_ago_price) / week_ago_price) * 100,
                'from_price': float(week_ago_price)
            }
        
        # 1ヶ月の変動
        if monthly_data is not None and not monthly_data.empty:
            month_ago_price = monthly_data['Close'].iloc[0]
            changes['month_change'] = {
                'absolute': current_price - month_ago_price,
                'percentage': ((current_price - month_ago_price) / month_ago_price) * 100,
                'from_price': float(month_ago_price)
            }
        
        # 1年の変動
        if yearly_data is not None and not yearly_data.empty:
            year_ago_price = yearly_data['Close'].iloc[0]
            changes['year_change'] = {
                'absolute': current_price - year_ago_price,
                'percentage': ((current_price - year_ago_price) / year_ago_price) * 100,
                'from_price': float(year_ago_price)
            }
        
        return changes
