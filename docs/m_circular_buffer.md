# `AXI-Stream BRAM Circular Buffer` Programming Manual

## IP 核简要描述

该 `IP` 核是原始数据的环形缓冲区.  
`IP` 核将数据存储到外接的 `BRAM`, `ARM` 端通过 `AXI-Full` 总线访问该存储设备, 读取其中 `16` 通道的原始信号数据, 这些数据将用于计算信号协方差矩阵.  

## 寄存器列表

| `Address` | `Name` | `R/W` | `Description` |
| :--- | :--- | :--- | :--- |
| `0x00` | `FREEZE` | `R/W` | 冻结控制寄存器 (Freeze) |
| `0x04` | `RST` | `R/W` | 软件复位 (Reset) |
| `0x08` | `RS` | `R` | 运行状态寄存器 (Run Status) |
| `0x0C` | `CBP` | `R/W` | 当前指针寄存器 (Current BRAM Pointer) |

### `FREEZE` (Freeze, offset = `00H`)

**FREEZE寄存器**
| Bits | Name | Description |
| :---: | :---: | :--- |
| `0` | `DO_FREEZE` | 1: 冻结, 0: 解冻 |
| `[31: 1]` | - | Reserved |

`DO_FREEZE` 位的值决定模块是否被冻结.  

### `RST` (Reset, offset = `04H`)

对该寄存器的写操作会触发模块复位.  

### `RS` (Run Status, offset = `08H`)

**FREEZE寄存器**
| Bits | Name | Description |
| :---: | :---: | :--- |
| `0` | `FREEZED` | 1: 模块已经被冻结, 0: 模块被解冻 |
| `1` | `REFRESHED` | 1: 模块完成数据刷新, 0: 模块没有完成数据刷新 |\
| `[31: 2]` | - | Reserved |

### `CBP` (Current BRAM Pointer, offset = `0CH`)

该寄存器记录了当前数据指针, 总是指向最新的数据位置.  

## 操作流程

`Step 1`: 向 `DO_FREEZE` 被写入 `1` 时, 模块被冻结, 环形缓冲区不再接受 `AXI-Stream` 总线发来的新数据, 同时环形缓冲区当前指针被固定.  
`Step 2`: 上位机在冻结后读取 `BRAM` 中的数据和寄存器 `CBP` 的值, 即可得到一段完整信号.  
`Step 3`: 得到完整信号后, 上位机向 `DO_FREEZE` 写入 `0`, 释放冻结.  
`Step 4`: 释放冻结后, 上位机必须复位模块, 重新开始收集数据, 否则数据将错位.  

---
_Shixuan Liu 2026_
