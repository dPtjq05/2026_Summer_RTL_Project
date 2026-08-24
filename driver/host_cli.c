#include <stdio.h>
#include <stdint.h>
#include "axi_regs.h"

// FPGA로 보낼 Write 패킷을 생성하는 함수
void build_write_packet(uint8_t *packet, uint32_t addr, uint32_t data) {
    packet[0] = CMD_AXI_WRITE;
    
    // Address (4 Bytes, Big-Endian)
    packet[1] = (addr >> 24) & 0xFF;    //addr[31:24]
    packet[2] = (addr >> 16) & 0xFF;    //addr[23:16]
    packet[3] = (addr >> 8)  & 0xFF;    //addr[15:8]
    packet[4] = addr & 0xFF;            //addr[7:0]

    // Data (4 Bytes, Big-Endian)
    packet[5] = (data >> 24) & 0xFF;
    packet[6] = (data >> 16) & 0xFF;
    packet[7] = (data >> 8)  & 0xFF;
    packet[8] = data & 0xFF;
}

void build_read_packet( uint8_t *packet, uint32_t addr) {   //read 동작을 위한 addr을 cmd와 함께 패킷에 담아서 보낸다.
    packet[0] = CMD_AXI_READ;
    
    // Address (4 Bytes, Big-Endian)
    packet[1] = (addr >> 24) & 0xFF;    //addr[31:24]
    packet[2] = (addr >> 16) & 0xFF;    //addr[23:16]
    packet[3] = (addr >> 8)  & 0xFF;    //addr[15:8]
    packet[4] = addr & 0xFF;            //addr[7:0]
}
uint32_t read_response(uint8_t *response) {     //read 동작을 시행하고 그 결과값을 받아온다.
    return ((uint32_t)response[0]<<24) | ((uint32_t)response[1]<<16) | ((uint32_t)response[2]<<8) | (uint32_t)response[3];
}
//더하기 연산자도 같은 값을 만들어내지만 하나의 비트에 노이즈가 발생했을 떄 위의 비트들도 다같이 값이 이상해지기 때문에 | 연산자를 쓴다.

//위의 함수는 내가 만든 모듈에서 cmd-addr-data 순서로 write 신호를 전송하는 함수다. 오랜만에 c언어 쓰니까 어색하다.
int main(void) {
    uint8_t tx_buf[5];
    uint32_t addr= 0x01011010;
    uint8_t resp[4]={0x01, 0x10, 0x01, 0x10};

    build_read_packet(tx_buf,addr);
    uint32_t result = read_response(resp);
    for (int i=0; i<5;i++){
        printf("%02x ", tx_buf[i]);
    }
    printf("\n");

    printf("Response: %08x\n", result);

}

/*
02 01 01 10 10 
*cmd-addr(4byte)
Response: 01100110


*/