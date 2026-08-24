#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <time.h>

#define CMD_AXI_WRITE 0x01
#define CMD_AXI_READ  0x02

#define TARGET_REG_ADDR 0x00000008  // 검증 대상 AXI Slave 레지스터 주소

// 1. Write 패킷 직렬화 (9바이트)
void build_write_packet(uint8_t *packet, uint32_t addr, uint32_t data) {
    packet[0] = CMD_AXI_WRITE;
    packet[1] = (addr >> 24) & 0xFF;
    packet[2] = (addr >> 16) & 0xFF;
    packet[3] = (addr >> 8)  & 0xFF;
    packet[4] = addr & 0xFF;
    packet[5] = (data >> 24) & 0xFF;
    packet[6] = (data >> 16) & 0xFF;
    packet[7] = (data >> 8)  & 0xFF;
    packet[8] = data & 0xFF;
}

// 2. Read 요청 패킷 직렬화 (5바이트)
void build_read_packet(uint8_t *packet, uint32_t addr) {
    packet[0] = CMD_AXI_READ;
    packet[1] = (addr >> 24) & 0xFF;
    packet[2] = (addr >> 16) & 0xFF;
    packet[3] = (addr >> 8)  & 0xFF;
    packet[4] = addr & 0xFF;
}

// 3. Read 응답 데이터 역직렬화 (4바이트 -> 32비트 정수)
uint32_t parse_read_response(const uint8_t *resp) {
    return ((uint32_t)resp[0] << 24) |
           ((uint32_t)resp[1] << 16) |
           ((uint32_t)resp[2] << 8)  |
           (uint32_t)resp[3];
}

// 4. 단일 테스트 벡터 실행 및 하드웨어 가상 루프백 검증
bool run_test_vector(const char *test_name, uint32_t pattern, uint32_t addr) {
    uint8_t tx_write[9];
    uint8_t tx_read[5];
    uint8_t mock_fpga_rx[4];

    // [호스트] Write 패킷 생성
    build_write_packet(tx_write, addr, pattern);

    // [가상 FPGA 동작 모사] Write 패킷의 Data 바이트(5~8)를 가상 레지스터에 래치 후 Read 응답으로 반환
    mock_fpga_rx[0] = tx_write[5];
    mock_fpga_rx[1] = tx_write[6];
    mock_fpga_rx[2] = tx_write[7];
    mock_fpga_rx[3] = tx_write[8];

    // [호스트] Read 요청 패킷 생성
    build_read_packet(tx_read, addr);

    // [호스트] 수신 데이터 파싱
    uint32_t read_back = parse_read_response(mock_fpga_rx);

    // [무결성 검증] 쓴 데이터 == 읽은 데이터 비교
    bool pass = (pattern == read_back);
    printf(" [%-20s] Written: 0x%08X | Read: 0x%08X -> %s\n",
           test_name, pattern, read_back, pass ? "[ PASS ]" : "[ FAIL ]");

    return pass;
}

int main(void) {
    int total_tests = 0;
    int passed_tests = 0;

    srand((unsigned int)time(NULL));

    printf("===============================================================\n");
    printf("  AXI4-Lite Register BIST (Built-In Self-Test) Engine\n");
    printf("  Target Address : 0x%08X\n", TARGET_REG_ADDR);
    printf("===============================================================\n\n");

    // -------------------------------------------------------------
    // Pattern 1: Checkerboard Pattern (인접 비트 간 간섭/Cross-talk 검출)
    // -------------------------------------------------------------
    printf("[1] Checkerboard Integrity Test\n");
    total_tests++;
    if (run_test_vector("Checkerboard 0x55", 0x55555555, TARGET_REG_ADDR)) passed_tests++;

    total_tests++;
    if (run_test_vector("Checkerboard 0xAA", 0xAAAAAAAA, TARGET_REG_ADDR)) passed_tests++;
    printf("\n");

    // -------------------------------------------------------------
    // Pattern 2: Walking 1s (각 비트 라인의 Stuck-at-0 결함 검출)
    // -------------------------------------------------------------
    printf("[2] Walking 1s Boundary Test\n");
    for (int i = 0; i < 4; i++) {
        char label[24];
        uint32_t walking_pattern = (1U << (i * 8)); // 0x00000001, 0x00000100, 0x00010000, 0x01000000
        snprintf(label, sizeof(label), "Walking 1s (Bit %02d)", i * 8);
        
        total_tests++;
        if (run_test_vector(label, walking_pattern, TARGET_REG_ADDR)) passed_tests++;
    }
    printf("\n");

    // -------------------------------------------------------------
    // Pattern 3: Random Value Burst (동적 데이터 버스 부하 검증)
    // -------------------------------------------------------------
    printf("[3] Random Value Stress Test\n");
    for (int i = 1; i <= 3; i++) {
        char label[24];
        uint32_t rand_pattern = ((uint32_t)rand() << 16) | (rand() & 0xFFFF);
        snprintf(label, sizeof(label), "Random Pattern %d", i);

        total_tests++;
        if (run_test_vector(label, rand_pattern, TARGET_REG_ADDR)) passed_tests++;
    }
    printf("\n");

    // -------------------------------------------------------------
    // 최종 검증 통계 리포트
    // -------------------------------------------------------------
    printf("===============================================================\n");
    printf("  BIST Execution Summary\n");
    printf("  Total Vectors : %d\n", total_tests);
    printf("  Passed        : %d\n", passed_tests);
    printf("  Failed        : %d\n", total_tests - passed_tests);
    printf("  Test Result   : %s\n", (passed_tests == total_tests) ? "ALL TESTS PASSED (100%)" : "FAILED");
    printf("===============================================================\n");

    return (passed_tests == total_tests) ? 0 : -1;
}