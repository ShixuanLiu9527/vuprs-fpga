# `AXI-Stream Beamforming Pre-delay Unit` Programming Manual

## IP 核简要描述

类似于 `Frost` 波束形成器的预延迟模块, 本模块可以完成时域整数周期延迟.

## 寄存器列表

| `Address` | `Name` | `R/W` | `Description` |
| :--- | :--- | :--- | :--- |
| `0x00` | `P_CH1_CH2` | `R/W` | 通道1, 通道2预延迟 (Pre-delay CH1 & CH2) |
| `0x04` | `P_CH3_CH4` | `R/W` | 通道3, 通道4预延迟 (Pre-delay CH3 & CH4) |
| `0x08` | `P_CH5_CH6` | `R/W` | 通道5, 通道6预延迟 (Pre-delay CH5 & CH6) |
| `0x0C` | `P_CH7_CH8` | `R/W` | 通道7, 通道8预延迟 (Pre-delay CH7 & CH8) |
| `0x10` | `P_CH9_CH10` | `R/W` | 通道9, 通道10预延迟 (Pre-delay CH9 & CH10) |
| `0x14` | `P_CH11_CH12` | `R/W` | 通道11, 通道12预延迟 (Pre-delay CH11 & CH12) |
| `0x18` | `P_CH13_CH14` | `R/W` | 通道13, 通道14预延迟 (Pre-delay CH13 & CH14) |
| `0x1C` | `P_CH15_CH16` | `R/W` | 通道15, 通道16预延迟 (Pre-delay CH15 & CH16) |
| `0x20` | `FREEZE` | `R/W` | 冻结控制寄存器 (Freeze) |
| `0x24` | `RST` | `R/W` | 软件复位 (Reset) |
| `0x28` | `RS` | `R` | 运行状态寄存器 (Run Status) |
| `0x2C` | `MPDLY` | `R` | 最大预延迟 (Maximum Pre-delay) |

### `P_CH1_CH2` (Pre-delay CH1 & CH2, offset = `00H`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `[15: 0]` | `P_CH1` | Pre-delay CH1 |
| `[31: 16]` | `P_CH2` | Pre-delay CH2 |

### `P_CH3_CH4` (Pre-delay CH3 & CH4, offset = `04H`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `[15: 0]` | `P_CH3` | Pre-delay CH3 |
| `[31: 16]` | `P_CH4` | Pre-delay CH4 |

### `P_CH5_CH6` (Pre-delay CH5 & CH6, offset = `08H`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `[15: 0]` | `P_CH5` | Pre-delay CH5 |
| `[31: 16]` | `P_CH6` | Pre-delay CH6 |

### `P_CH7_CH8` (Pre-delay CH7 & CH8, offset = `0CH`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `[15: 0]` | `P_CH7` | Pre-delay CH7 |
| `[31: 16]` | `P_CH8` | Pre-delay CH8 |

### `P_CH9_CH10` (Pre-delay CH9 & CH10, offset = `10H`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `[15: 0]` | `P_CH9` | Pre-delay CH9 |
| `[31: 16]` | `P_CH10` | Pre-delay CH10 |

### `P_CH11_CH12` (Pre-delay CH11 & CH12, offset = `14H`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `[15: 0]` | `P_CH11` | Pre-delay CH11 |
| `[31: 16]` | `P_CH12` | Pre-delay CH12 |

### `P_CH13_CH14` (Pre-delay CH13 & CH14, offset = `18H`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `[15: 0]` | `P_CH13` | Pre-delay CH13 |
| `[31: 16]` | `P_CH14` | Pre-delay CH14 |

### `P_CH15_CH16` (Pre-delay CH15 & CH16, offset = `1CH`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `[15: 0]` | `P_CH15` | Pre-delay CH15 |
| `[31: 16]` | `P_CH16` | Pre-delay CH16 |

### `FREEZE` (Freeze, offset = `20H`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `0` | `DO_FREEZE` | 冻结控制位：<br/>- `1'b0`: 正常操作模式<br/>- `1'b1`: 冻结所有通道的预延迟配置 |
| `[31: 1]` | - | Reserved |

### `RST` (Reset, offset = `24H`)

对寄存器的写入操作会触发复位.  

### `RS` (Run Status, offset = `28H`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `0` | `FREEZED` | 1: 模块被冻结, 0: 模块没有被冻结 |
| `1` | `REFRESHED` | 1: 数据已经刷新, 0: 数据没有刷新 |
| `[31: 2]` | - | Reserved |

### `MPDLY` (Maximum Pre-delay, offset = `2CH`)

| Bits | Name | Description |
| :---: | :---: | :--- |
| `[15: 0]` | `MAX_PDLY` | 硬件支持的最大预延迟值 (只读) |
| `[31: 16]` | - | Reserved |

## 操作流程

`Step 1`: 向 `DO_FREEZE` 被写入 `1` 时, 模块被冻结, 不再接受 `AXI-Stream` 总线发来的新数据.  
`Step 2`: 上位机在冻结后通过 `AXI-Lite` 总线配置各个通道的预延迟参数.  
`Step 3`: 向 `DO_FREEZE` 被写入 `0`, 释放冻结.  

---
_Shixuan Liu 2026_
