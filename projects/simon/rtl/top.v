module top (
	// UART (to RP2040)
	output wire       uart_tx,
	input  wire       uart_rx,

	// IRQ (to ESP32)
	output wire       irq_n,

	// SPI Slave (to ESP32)
	input  wire       spi_mosi,
	output wire       spi_miso,
	input  wire       spi_clk,
	input  wire       spi_cs_n,

	// PSRAM
	inout  wire [3:0] ram_io,
	output wire       ram_clk,
	output wire       ram_cs_n,

  // LCD
  output reg  [7:0] lcd_d,
  output reg        lcd_rs,
  output            lcd_wr_n,
  output            lcd_cs_n,
  output            lcd_rst_n,
  input             lcd_fmark,
  input             lcd_mode,

	// PMOD
	inout  wire [7:0] pmod,

	// RGB Leds
	output wire [2:0] rgb,

	// Clock
	input  wire       clk_in
);

  wire clk = clk_in; // 12 MHz

  // ######   Reset logic   ###################################

  wire reset_button = 1'b1; // No reset button on this board

  reg [15:0] reset_cnt = 0;
  wire resetq = &reset_cnt;

  always @(posedge clk) begin
    if (reset_button) reset_cnt <= reset_cnt + !resetq;
    else        reset_cnt <= 0;
  end

  // ######   LEDs   ##########################################
  wire red;
  wire green;
  wire blue;

  SB_RGBA_DRV #(
      .CURRENT_MODE("0b1"),       // half current
      .RGB0_CURRENT("0b000011"),  // 4 mA
      .RGB1_CURRENT("0b000011"),  // 4 mA
      .RGB2_CURRENT("0b000011")   // 4 mA
  ) RGBA_DRIVER (
      .CURREN(1'b1),
      .RGBLEDEN(1'b1),
      .RGB1PWM(red),
      .RGB2PWM(green),
      .RGB0PWM(blue),
      .RGB0(rgb[0]),
      .RGB1(rgb[1]),
      .RGB2(rgb[2])
  );

  wire [3:0] btn;
  wire [3:0] led;
  wire sound;

  assign ram_clk = sound;

  SB_IO #(.PIN_TYPE(6'b1010_00)) ioled0 (.PACKAGE_PIN(pmod[0]), .OUTPUT_ENABLE(1), .D_OUT_0(led[0]), .INPUT_CLK(clk) );
  SB_IO #(.PIN_TYPE(6'b1010_00)) ioled1 (.PACKAGE_PIN(pmod[1]), .OUTPUT_ENABLE(1), .D_OUT_0(led[1]), .INPUT_CLK(clk) );
  SB_IO #(.PIN_TYPE(6'b1010_00)) ioled2 (.PACKAGE_PIN(pmod[2]), .OUTPUT_ENABLE(1), .D_OUT_0(led[2]), .INPUT_CLK(clk) );
  SB_IO #(.PIN_TYPE(6'b1010_00)) ioled3 (.PACKAGE_PIN(pmod[3]), .OUTPUT_ENABLE(1), .D_OUT_0(led[3]), .INPUT_CLK(clk) );

  SB_IO #(.PIN_TYPE(6'b1010_00), .PULLUP(1)) iobtn0 (.PACKAGE_PIN(pmod[4]), .D_IN_0(btn[0]), .OUTPUT_ENABLE(0), .INPUT_CLK(clk) );
  SB_IO #(.PIN_TYPE(6'b1010_00), .PULLUP(1)) iobtn1 (.PACKAGE_PIN(pmod[5]), .D_IN_0(btn[1]), .OUTPUT_ENABLE(0), .INPUT_CLK(clk) );
  SB_IO #(.PIN_TYPE(6'b1010_00), .PULLUP(1)) iobtn2 (.PACKAGE_PIN(pmod[6]), .D_IN_0(btn[2]), .OUTPUT_ENABLE(0), .INPUT_CLK(clk) );
  SB_IO #(.PIN_TYPE(6'b1010_00), .PULLUP(1)) iobtn3 (.PACKAGE_PIN(pmod[7]), .D_IN_0(btn[3]), .OUTPUT_ENABLE(0), .INPUT_CLK(clk) );

  /* Simon */
  simon simon1 (
      .clk   (clk),
      .rst   (~resetq),
      .ticks_per_milli (12000),
      .btn   (~btn),
      .led   (led),
      .sound (sound)
  );
endmodule