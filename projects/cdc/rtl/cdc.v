
`default_nettype none // Simplifies finding typos

localparam BIT_SAMPLES = 'd4;

module top(
  input wire clk_in,
  output [2:0] rgb, // LED outputs. [0]: Green, [1]: Red, [2]: Blue.
	inout wire [7:0] pmod
);
  wire clk;
  wire clk_pll;
  wire pll_lock;

	// PLL
  SB_PLL40_PAD  #(
    .FEEDBACK_PATH("SIMPLE"),
    .PLLOUT_SELECT("GENCLK"),
    .DIVR(0),
    .DIVF(7'b0111111),
    .DIVQ(3'b011),
    .FILTER_RANGE(1),
  ) pll (
    .PACKAGEPIN(clk_in),
    .PLLOUTCORE(clk_pll),
    .LOCK(pll_lock),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .SCLK(1'b0),
    .LATCHINPUTVALUE(1'b1)
  );

  wire clk;
  wire clk_4x;

  prescaler u_prescaler (.clk_i(clk_pll),
                        .rstn_i(pll_lock),
                        .clk_div2_o(clk_4x),
                        .clk_div4_o(),
                        .clk_div8_o(clk),
                        .clk_div16_o());


  // ----------------------------------------------------------
  //   Simple gray counter blinky
  // ----------------------------------------------------------

  reg [31:0] counter;

  always @(posedge clk) counter <= counter + 1;

  wire red, green, blue;

  assign {blue, green, red} = counter[25:23] ^ counter[25:24];

  // ----------------------------------------------------------
  // Instantiate iCE40 LED driver hard logic.
  // ----------------------------------------------------------
  //
  // Note that it's possible to drive the LEDs directly,
  // however that is not current-limited and results in
  // overvolting the red LED.
  //
  // See also:
  // https://www.latticesemi.com/-/media/LatticeSemi/Documents/ApplicationNotes/IK/ICE40LEDDriverUsageGuide.ashx?document_id=50668

  SB_RGBA_DRV #(
      .CURRENT_MODE("0b1"),       // half current
      .RGB0_CURRENT("0b000011"),  // 4 mA
      .RGB1_CURRENT("0b000011"),  // 4 mA
      .RGB2_CURRENT("0b000011")   // 4 mA
  ) RGBA_DRIVER (
      .CURREN(1'b1),
      .RGBLEDEN(1'b1),
      .RGB0PWM(green),
      .RGB1PWM(red),
      .RGB2PWM(blue),      
      .RGB0(rgb[0]),
      .RGB1(rgb[1]),
      .RGB2(rgb[2])
  );

  // ######   Reset logic   ###################################

  reg [4:0]index;
  wire [8*22-1:0]hello = "Hello, Tiny Tapeout!\r\n";
  reg in_valid_i;
  wire in_ready;
  reg [7:0]char;

  always @(posedge clk) begin
    if (!pll_lock) begin
      index <= 0;
      in_valid_i <= 0;
    end else begin
      if ($rose(in_ready)) begin
        in_valid_i <= 1;
        char <= hello[{index, 3'b000}+:8];
        if (index == 0) begin
          index = 21;
        end else begin
          index = index - 1;
        end
      end else begin
        in_valid_i <= 0;
      end
    end
  end

  wire dp_pu_o;
  wire configured_o;
  wire usb_tx_en;

  wire dp_rx_i;
  wire dn_rx_i;
  wire dp_tx_o;
  wire dn_tx_o;

  SB_IO #(.PIN_TYPE(6'b1010_01)) iocnt0 (.PACKAGE_PIN(pmod[0]), .OUTPUT_ENABLE(usb_tx_en), .D_IN_0(dp_rx_i), .D_OUT_0(dp_tx_o), .INPUT_CLK(1'b0), .LATCH_INPUT_VALUE(1'b0) );
  SB_IO #(.PIN_TYPE(6'b1010_01)) iocnt1 (.PACKAGE_PIN(pmod[1]), .OUTPUT_ENABLE(usb_tx_en), .D_IN_0(dn_rx_i), .D_OUT_0(dn_tx_o), .INPUT_CLK(1'b0), .LATCH_INPUT_VALUE(1'b0) );
  SB_IO #(.PIN_TYPE(6'b1010_00)) iocnt2 (.PACKAGE_PIN(pmod[2]), .OUTPUT_ENABLE(1), .D_OUT_0(index), .INPUT_CLK(clk_4x) );
  SB_IO #(.PIN_TYPE(6'b1010_00)) iocnt3 (.PACKAGE_PIN(pmod[3]), .OUTPUT_ENABLE(1), .D_OUT_0(dp_pu_o), .INPUT_CLK(clk_4x) );
  SB_IO #(.PIN_TYPE(6'b1010_00)) iocnt4 (.PACKAGE_PIN(pmod[4]), .OUTPUT_ENABLE(1), .D_OUT_0(dp_tx_o), .INPUT_CLK(1'b0), .LATCH_INPUT_VALUE(1'b0) );
  SB_IO #(.PIN_TYPE(6'b1010_00)) iocnt6 (.PACKAGE_PIN(pmod[6]), .OUTPUT_ENABLE(1), .D_OUT_0(configured_o), .INPUT_CLK(clk_4x) );
  SB_IO #(.PIN_TYPE(6'b1010_00)) iocnt7 (.PACKAGE_PIN(pmod[7]), .OUTPUT_ENABLE(1), .D_OUT_0(clk_4x), .INPUT_CLK(clk_4x) );

   wire [7:0]       out_data;
   wire             out_valid;
   wire             in_ready;

  /* USB Serial */
   usb_cdc #(
      .VENDORID(16'h16c0),
      .PRODUCTID(16'h05e1),
      .IN_BULK_MAXPACKETSIZE('d8),
      .OUT_BULK_MAXPACKETSIZE('d8),
      .BIT_SAMPLES(BIT_SAMPLES),
      .USE_APP_CLK(1),
      .APP_CLK_RATIO(BIT_SAMPLES*12/12)    // BIT_SAMPLES * 12MHz / 12MHz
  ) u_usb_cdc (
      .frame_o(),
      .configured_o(configured_o),
      
      .app_clk_i(clk),
      .clk_i(clk_4x),
      .rstn_i(pll_lock),
      .out_ready_i(in_ready),
      .in_data_i(char),
      .in_valid_i(in_valid_i),
      .dp_rx_i(dp_rx_i),
      .dn_rx_i(dn_rx_i),

      .out_data_o(out_data),
      .out_valid_o(out_valid),
      .in_ready_o(in_ready),
      .dp_pu_o(dp_pu_o),
      .tx_en_o(usb_tx_en),
      .dp_tx_o(dp_tx_o),
      .dn_tx_o(dn_tx_o)
	);

endmodule
