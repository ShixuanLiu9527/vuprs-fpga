# `AXI-Stream FIR Filter Bank` Programming Manual

## IP 核简要描述

本系统通过该 `IP` 核的 `FIR` 滤波器组完成时域宽带声学波束形成.  
滤波器系数存储与外挂的 `BRAM` 中, 可通过 `AXI-Full` 读写.  

## 寄存器列表

根据您提供的寄存器定义，我将为您整理成规范的寄存器列表表格：

## 寄存器列表

| `Address` | `Name` | `R/W` | `Description` |
| :---: | :---: | :---: | :--- |
| `0x00` | `RST` | `R/W` | 软件复位寄存器 (Reset) |
| `0x04` | `UPDATE_FLEN` | `R/W` | FIR长度更新寄存器 (Update FIR Length) |
| `0x08` | `UPDATE_FCOEF` | `R/W` | FIR系数更新寄存器 (Update FIR Coefficient) |
| `0x0C` | `FIR_LEN` | `R/W` | FIR长度配置寄存器 (FIR Length) |
| `0x10` | `FIR_COEF_SCALE` | `R/W` | FIR系数缩放寄存器 (FIR Coefficient Scale) |
| `0x14` | `RSC` | `R/W` | 运行状态控制寄存器 (Run Status Control) |
| `0x18` | `RS` | `R` | 运行状态寄存器 (Run Status) |
| `0x1C` | `MAX_FLEN` | `R` | 最大FIR长度寄存器 (Maximum FIR Length) |

### `RST` (Reset, offset = `00H`)

对寄存器的写入操作会触发复位.  

### `UPDATE_FLEN` (Update FIR Length, offset = `04H`)

对该寄存器的写入操作会触发滤波器组 `长度更新` 和 `系数更新`.  

### `UPDATE_FCOEF` (Update FIR Coefficient, offset = `08H`)

对该寄存器的写入操作会触发滤波器组 `系数更新`.  

### `FIR_LEN` (FIR Length, offset = `0CH`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `[31: 0]` | `FIR_LENGTH` | FIR 滤波器长度值 |

### `FIR_COEF_SCALE` (FIR Coefficient Scale, offset = `10H`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `[31: 0]` | `COEF_SCALE` | FIR系数缩放因子值 (Q16.16 定点数) |

### `RSC` (Run Status Control, offset = `14H`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `0` | `RUN_EN` | 运行使能控制位：<br/>- `1'b0`: 停止运行<br/>- `1'b1`: 使能运行 |
| `[31: 1]` | - | Reserved |

### `RS` (Run Status, offset = `18H`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `0` | `REFRESHED` | 刷新状态指示位：<br/>- `1'b0`: 未刷新<br/>- `1'b1`: 已刷新 |
| `1` | `LEN_UPDATED` | FIR长度更新状态指示位：<br/>- `1'b0`: 长度未更新<br/>- `1'b1`: 长度已更新 |
| `2` | `COEF_UPDATED` | FIR系数更新状态指示位：<br/>- `1'b0`: 系数未更新<br/>- `1'b1`: 系数已更新 |
| `[31: 1]` | - | Reserved |

### `MAX_FLEN` (Maximum FIR Length, offset = `1CH`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `[31: 0]` | `MAX_FLENGTH` | 硬件支持的最大FIR滤波器长度 (只读) |

## 操作流程

`Step 1`: 将新的滤波器系数写入模块外挂 `BRAM`.  
`Step 2`: 如果需要, 将新的滤波器长度写入 `FIR_LEN`.  
`Step 3`: 触发长度更新, 写寄存器 `UPDATE_FLEN`.  

---
_Shixuan Liu 2026_
