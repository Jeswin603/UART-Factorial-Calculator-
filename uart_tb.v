module uart_tx_rx_tb;

  // Parameters
  parameter DBIT = 8;          // Number of data bits
  parameter SB_TICK = 16;      // Number of ticks for the stop bit
  parameter CLKS_PER_BIT = 10416; // For 9600 baud rate with a 100 MHz clock
  
  // Clock and reset
  reg clk;
  reg reset;

  // Transmitter signals
  reg [7:0] tx_data;
  reg tx_start;
  wire tx_busy;
  wire tx;

  // Receiver signals
  wire [7:0] rx_data;
  wire rx_done_tick;
  reg sel;
  reg rx;

  // Baud rate generator
  reg [13:0] tick_counter;
  wire s_tick;  // Baud rate tick
  
  assign s_tick = (tick_counter == (CLKS_PER_BIT - 1));

  // Internal flag to check data transfer
  reg data_received_flag;

  // Array for data to send and an index variable
  reg [7:0] data_to_send [2:0];
  integer i;

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100 MHz clock
  end

  // Reset generation
  initial begin
    reset = 1;
    #10 reset = 0;
  end

  // Baud rate tick generator
  always @(posedge clk or posedge reset) begin
    if (reset)
      tick_counter <= 0;
    else if (s_tick)
      tick_counter <= 0;
    else
      tick_counter <= tick_counter + 1;
  end

  // Instantiate UART transmitter
  uart_tx #(
    .DBIT(DBIT),
    .SB_TICK(SB_TICK)
  ) uart_tx_inst (
    .clk(clk),
    .reset(reset),
    .tx_start(tx_start),
    .s_tick(s_tick),
    .din(tx_data),
    .tx(tx),
    .tx_done_tick(tx_busy)
  );

  // Instantiate UART receiver
  uart_rx #(
    .DBIT(DBIT),
    .SB_TICK(SB_TICK)
  )
  uart_rx_inst (
    .clk(clk),
    .reset(reset),
    .rx(tx),
    .s_tick(s_tick),
    .dout(rx_data),
    .rx_done_tick(rx_done_tick),
    .sel(sel)
  );

  // Test stimulus
  initial begin
    // Initialize signals
    tx_start = 0;
    rx = 1;
    tx_data = 0;
    data_received_flag = 0;

    // Initialize the data array
    data_to_send[0] = 8'b10101010;
    data_to_send[1] = 8'b00001111;
   

    // Wait for reset
    #20;

    for (i = 0; i < 2; i = i + 1) begin
      // Transmit a byte
      sel=i;
      tx_data = data_to_send[i];
      tx_start = 1;
      #10;
      tx_start = 0;

      // Wait for data to be received
      wait(rx_done_tick);

      // Check received data
      if (rx_data == tx_data) begin
        data_received_flag = 1;
        $display("Time: %0t ns - Data successfully transmitted and received: %h", $time, rx_data);
      end else begin
        $display("Time: %0t ns - Data mismatch! Transmitted: %h, Received: %h", $time, tx_data, rx_data);
      end

      // Wait for some time before sending the next byte
      #1_000_000;  // 1 millisecond in simulation time
    end

    // End simulation
    $display("Time: %0t ns - Simulation ended after all data transmitted and received.", $time);
    $stop;
  end

endmodule
