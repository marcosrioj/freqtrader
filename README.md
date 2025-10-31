# Freqtrade Setup Guide for Bybit Real Money Trading

This guide will walk you through setting up Freqtrade for real money cryptocurrency trading on Bybit exchange.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Bybit Account Setup](#bybit-account-setup)
4. [Freqtrade Configuration](#freqtrade-configuration)
5. [Strategy Development](#strategy-development)
6. [Testing with Paper Trading](#testing-with-paper-trading)
7. [Live Trading Setup](#live-trading-setup)
8. [Monitoring and Maintenance](#monitoring-and-maintenance)
9. [Security Best Practices](#security-best-practices)
10. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements
- Linux/macOS/Windows with WSL2
- Python 3.8 or higher
- Git
- At least 4GB RAM
- Stable internet connection

### Knowledge Requirements
- Basic understanding of cryptocurrency trading
- Basic command line usage
- Understanding of trading concepts (stop loss, take profit, etc.)
- Risk management principles

## Installation

### Step 1: Install Python and Dependencies

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Python and pip
sudo apt install python3 python3-pip python3-venv git -y

# Install TA-Lib (required for technical analysis)
sudo apt install libta-lib-dev -y
```

### Step 2: Clone and Install Freqtrade

```bash
# Clone Freqtrade repository
git clone https://github.com/freqtrade/freqtrade.git
cd freqtrade

# Create virtual environment
python3 -m venv freqtrade-env
source freqtrade-env/bin/activate

# Install Freqtrade
pip install -e .

# Install additional dependencies for plotting and optimization
pip install freqtrade[plot,hyperopt]
```

### Step 3: Verify Installation

```bash
freqtrade --version
```

## Bybit Account Setup

### Step 1: Create Bybit Account
1. Go to [Bybit.com](https://www.bybit.com)
2. Sign up for a new account
3. Complete KYC verification (required for higher limits)
4. Enable 2FA (Two-Factor Authentication)

### Step 2: Fund Your Account
1. Deposit cryptocurrency or fiat to your Bybit account
2. Transfer funds to your trading account
3. **Important**: Start with a small amount for testing!

### Step 3: Create API Keys
1. Go to Account Settings → API Management
2. Create a new API key with the following permissions:
   - **Trading**: Read and Write
   - **Wallet**: Read only (for balance checking)
   - **Position**: Read and Write
3. **Security Settings**:
   - Enable IP whitelist (add your server's IP)
   - Set API key expiration date
   - Save your API key and secret securely

⚠️ **NEVER share your API keys with anyone!**

## Freqtrade Configuration

### Step 1: Create Configuration Directory

```bash
# Create user data directory
mkdir user_data
cd user_data
mkdir strategies logs backtest_results plot
```

### Step 2: Generate Base Configuration

```bash
# Generate configuration file
freqtrade create-userdir --userdir user_data

# Create initial configuration
freqtrade new-config --config user_data/config.json
```

### Step 3: Configure for Bybit

Create or edit `user_data/config.json`:

```json
{
    "max_open_trades": 3,
    "stake_currency": "USDT",
    "stake_amount": 20,
    "tradable_balance_ratio": 0.99,
    "fiat_display_currency": "USD",
    "dry_run": true,
    "dry_run_wallet": 1000,
    "cancel_open_orders_on_exit": false,
    "trading_mode": "spot",
    "margin_mode": "",
    "unfilledtimeout": {
        "entry": 10,
        "exit": 10,
        "exit_timeout_count": 0,
        "unit": "minutes"
    },
    "entry_pricing": {
        "price_side": "same",
        "use_order_book": true,
        "order_book_top": 1,
        "price_last_balance": 0.0,
        "check_depth_of_market": {
            "enabled": false,
            "bids_to_ask_delta": 1
        }
    },
    "exit_pricing": {
        "price_side": "same",
        "use_order_book": true,
        "order_book_top": 1
    },
    "exchange": {
        "name": "bybit",
        "key": "YOUR_API_KEY_HERE",
        "secret": "YOUR_API_SECRET_HERE",
        "ccxt_config": {
            "enableRateLimit": true,
            "sandbox": false
        },
        "ccxt_async_config": {
            "enableRateLimit": true,
            "rateLimit": 100
        },
        "pair_whitelist": [
            "BTC/USDT",
            "ETH/USDT",
            "ADA/USDT",
            "DOT/USDT",
            "LTC/USDT"
        ],
        "pair_blacklist": [
            "BNB/.*"
        ]
    },
    "pairlists": [
        {
            "method": "StaticPairList"
        }
    ],
    "edge": {
        "enabled": false,
        "process_throttle_secs": 3600,
        "calculate_since_number_of_days": 7,
        "allowed_risk": 0.01,
        "stoploss_range_min": -0.01,
        "stoploss_range_max": -0.1,
        "stoploss_range_step": -0.01,
        "minimum_winrate": 0.60,
        "minimum_expectancy": 0.20,
        "min_trade_number": 10,
        "max_trade_duration_minute": 1440,
        "remove_pumps": false
    },
    "telegram": {
        "enabled": false,
        "token": "",
        "chat_id": ""
    },
    "api_server": {
        "enabled": false,
        "listen_ip_address": "127.0.0.1",
        "listen_port": 8080,
        "verbosity": "error",
        "enable_openapi": false,
        "jwt_secret_key": "somethingrandom",
        "ws_token": "samplews",
        "CORS_origins": [],
        "username": "",
        "password": ""
    },
    "bot_name": "freqtrade",
    "initial_state": "running",
    "force_entry_enable": false,
    "internals": {
        "process_throttle_secs": 5
    }
}
```

## Strategy Development

### Step 1: Create a Simple Strategy

Create `user_data/strategies/simple_strategy.py`:

```python
import talib.abstract as ta
from freqtrade.strategy.interface import IStrategy
from freqtrade.strategy import DecimalParameter, IntParameter
from pandas import DataFrame
import freqtrade.vendor.qtpylib.indicators as qtpylib

class SimpleStrategy(IStrategy):
    """
    Simple RSI + Moving Average strategy for beginners
    """
    
    # Strategy interface version
    INTERFACE_VERSION = 3

    # Minimal ROI designed for the strategy
    minimal_roi = {
        "60": 0.01,
        "30": 0.02,
        "0": 0.04
    }

    # Optimal stoploss
    stoploss = -0.10

    # Optimal timeframe for the strategy
    timeframe = '5m'
    
    # Run "populate_indicators" only for new candle
    process_only_new_candles = False

    # These values can be overridden in the "ask_strategy" section in the config
    use_exit_signal = True
    exit_profit_only = False
    ignore_roi_if_entry_signal = False

    # Number of candles the strategy requires before producing valid signals
    startup_candle_count: int = 30

    # Strategy parameters
    buy_rsi = IntParameter(10, 40, default=30, space="buy")
    sell_rsi = IntParameter(60, 90, default=70, space="sell")
    short_ma = IntParameter(5, 25, default=10, space="buy")
    long_ma = IntParameter(20, 50, default=30, space="buy")

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Add several TA indicators to the given DataFrame
        """
        # RSI
        dataframe['rsi'] = ta.RSI(dataframe)
        
        # Moving Averages
        dataframe['ma_short'] = ta.SMA(dataframe, timeperiod=self.short_ma.value)
        dataframe['ma_long'] = ta.SMA(dataframe, timeperiod=self.long_ma.value)
        
        # MACD
        macd = ta.MACD(dataframe)
        dataframe['macd'] = macd['macd']
        dataframe['macdsignal'] = macd['macdsignal']
        dataframe['macdhist'] = macd['macdhist']

        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Based on TA indicators, populates the entry signal for the given dataframe
        """
        dataframe.loc[
            (
                # RSI is oversold
                (dataframe['rsi'] < self.buy_rsi.value) &
                # Short MA is above long MA (uptrend)
                (dataframe['ma_short'] > dataframe['ma_long']) &
                # MACD is positive
                (dataframe['macd'] > dataframe['macdsignal']) &
                # Volume is not 0
                (dataframe['volume'] > 0)
            ),
            'enter_long'] = 1

        return dataframe

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Based on TA indicators, populates the exit signal for the given dataframe
        """
        dataframe.loc[
            (
                # RSI is overbought
                (dataframe['rsi'] > self.sell_rsi.value) &
                # Short MA is below long MA (downtrend)
                (dataframe['ma_short'] < dataframe['ma_long']) &
                # Volume is not 0
                (dataframe['volume'] > 0)
            ),
            'exit_long'] = 1

        return dataframe
```

## Testing with Paper Trading

### Step 1: Download Historical Data

```bash
# Download historical data for backtesting
freqtrade download-data --exchange bybit --timeframes 5m 1h --days 30 --config user_data/config.json
```

### Step 2: Backtest Your Strategy

```bash
# Run backtest
freqtrade backtesting --config user_data/config.json --strategy SimpleStrategy --timeframe 5m --timerange 20241001-20241030
```

### Step 3: Paper Trading (Dry Run)

```bash
# Ensure dry_run is set to true in config.json
# Start paper trading
freqtrade trade --config user_data/config.json --strategy SimpleStrategy
```

Monitor the paper trading for at least a week to validate your strategy performance.

## Live Trading Setup

⚠️ **WARNING: Only proceed to live trading after thoroughly testing with paper trading!**

### Step 1: Update Configuration for Live Trading

Edit `user_data/config.json`:

```json
{
    "dry_run": false,
    "dry_run_wallet": 0,
    // ... rest of configuration
}
```

### Step 2: Add Your Real API Keys

```json
{
    "exchange": {
        "name": "bybit",
        "key": "YOUR_REAL_API_KEY",
        "secret": "YOUR_REAL_API_SECRET",
        // ... rest of exchange config
    }
}
```

### Step 3: Set Conservative Parameters

```json
{
    "max_open_trades": 1,
    "stake_amount": 10,
    "tradable_balance_ratio": 0.1,
    // ... rest of configuration
}
```

### Step 4: Start Live Trading

```bash
# Start live trading (use screen or tmux for persistence)
screen -S freqtrade
freqtrade trade --config user_data/config.json --strategy SimpleStrategy

# Detach from screen: Ctrl+A, then D
# Reattach: screen -r freqtrade
```

## Monitoring and Maintenance

### Set Up Telegram Notifications

1. Create a Telegram bot via @BotFather
2. Get your chat ID
3. Update config.json:

```json
{
    "telegram": {
        "enabled": true,
        "token": "YOUR_BOT_TOKEN",
        "chat_id": "YOUR_CHAT_ID"
    }
}
```

### Set Up FreqUI (Web Interface)

```bash
# Install FreqUI
pip install freqUI

# Enable in config.json
{
    "api_server": {
        "enabled": true,
        "listen_ip_address": "127.0.0.1",
        "listen_port": 8080,
        "username": "your_username",
        "password": "your_password"
    }
}

# Access at http://localhost:8080
```

### Regular Maintenance Tasks

1. **Daily**: Check trades and performance
2. **Weekly**: Review strategy performance and adjust if needed
3. **Monthly**: Update Freqtrade and dependencies
4. **Ongoing**: Monitor market conditions and strategy effectiveness

## Security Best Practices

### API Security
- Use IP whitelisting for API keys
- Set API key expiration dates
- Never commit API keys to version control
- Use environment variables for sensitive data

### Server Security
- Keep system updated
- Use strong passwords
- Enable firewall
- Monitor system logs

### Trading Security
- Start with small amounts
- Set strict stop losses
- Don't risk more than you can afford to lose
- Keep backups of configurations

## Troubleshooting

### Common Issues

1. **Installation Problems**
   ```bash
   # If TA-Lib installation fails
   sudo apt install build-essential
   pip install --upgrade setuptools wheel
   ```

2. **API Connection Issues**
   - Verify API keys are correct
   - Check IP whitelist settings
   - Ensure sufficient API rate limits

3. **Strategy Not Trading**
   - Check if conditions are met
   - Verify pair whitelist
   - Check available balance

4. **Performance Issues**
   - Reduce number of pairs
   - Increase timeframe
   - Optimize strategy parameters

### Log Analysis

```bash
# View live logs
tail -f user_data/logs/freqtrade.log

# Search for errors
grep -i error user_data/logs/freqtrade.log
```

### Getting Help

- [Freqtrade Documentation](https://www.freqtrade.io/)
- [Freqtrade Discord](https://discord.gg/p7nuUNVfP7)
- [GitHub Issues](https://github.com/freqtrade/freqtrade/issues)

---

## Important Disclaimers

⚠️ **RISK WARNING**: 
- Cryptocurrency trading involves substantial risk
- Past performance does not guarantee future results
- Only trade with money you can afford to lose
- This guide is for educational purposes only
- Always do your own research

🔐 **SECURITY WARNING**:
- Never share your API keys
- Always test with paper trading first
- Use strong, unique passwords
- Keep your system and software updated

📊 **PERFORMANCE WARNING**:
- No strategy guarantees profits
- Market conditions change constantly
- Regular monitoring and adjustment required
- Consider professional financial advice

---

**Happy Trading! 🚀**

Remember: The best trader is a well-informed, patient, and disciplined trader.
