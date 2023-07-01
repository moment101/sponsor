# Description

** 保本的贊助專案 **

贊助方可以自由選擇要贊助的人/團體/專案，投入 ETH 後可以換得 LToken，之後可 1:1 換回 ETH，
專案利用這些資金去投資，將賺來的利息轉給被贊助者。

# Framework

1.  Factory 部署建立新的贊助專案合約，任何人都可以上架，需要提供被贊助者的一些資訊(address, url...),
    加入的專案在這份合約中可以查詢，與管理，方便前端串接
2.  LToken Proxy / LToken Implementation， 贊助者的互動合約，可以在這裡 Mint / Redeem，
3.  Controller 負責將資金拿去做投資與贖回，將收益轉給被贊助者。

                       -------------------------------
                       | LToken1  <=> LTokenDelegate   |
         Factory ----> | LToken2 <=> LTokenDelegate    |
                       | ....... ....                  |
                       |-------------------------------|
                                   Controller  <========================> Compound / AAVE

# Development

# Testing

# Usage
