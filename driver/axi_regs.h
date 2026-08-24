#ifndef AXI_REGS_H
#define AXI_REGS_H

#include <stdint.h>

/* AXI Base Address */
#define AXI_BASE_ADDR        0x00000000

/* Register Offsets */
#define REG_DUMMY0_OFFSET    0x00000008
#define REG_STATUS_OFFSET    0x0000000C

/* Memory-Mapped Register Addresses */
#define REG_DUMMY0_ADDR      (AXI_BASE_ADDR + REG_DUMMY0_OFFSET)
#define REG_STATUS_ADDR      (AXI_BASE_ADDR + REG_STATUS_OFFSET)

/* Protocol Command Opcode */
#define CMD_AXI_WRITE        0x01
#define CMD_AXI_READ         0x02

/* Status & Response Codes */
#define RESP_OKAY            0x00
#define RESP_ERROR           0xFF

#endif /* AXI_REGS_H */