# 1A2B_SICXE
1A2B Game (猜數字遊戲)

以 SIC/XE 組合語言實作的經典 1A2B 猜數字遊戲，並透過 SicTools 虛擬機執行。本專案具備完整的遊戲迴圈、亂數種子生成、輸入驗證以及歷史紀錄功能，展現了系統程式底層的記憶體操作與 I/O 設備整合。

## 系統需求 (Prerequisites)

* **Java**: 執行 SicTools 模擬器必備 (`java` 指令需在環境變數中)。
* **PowerShell**: 供執行自動化啟動與亂數產生腳本。

## 執行方式 (How to Run)

請先開啟終端機（如 PowerShell），並切換至專案目錄：
```powershell
cd c:\Users\sansa\OneDrive\桌面\1A2B_SICXE
```
### 一鍵啟動 (推薦)
此腳本會先產生亂數種子，接著自動組譯並啟動遊戲：

  **CLI 版**（直接於終端機內遊玩）：
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\run-random.ps1
  ```
  **GUI 版**（會開啟 SicTools 視窗）
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\run-random.ps1 -Gui
  ```
  **開 SicTools GUI Simulator**
  ```powershell
  java -jar sictools.jar -freq 100000 game.asm
  ```
