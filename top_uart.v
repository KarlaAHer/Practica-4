// Modulo principal UART
// Recibe la base y el numerador
// Calcula base^(numerador/2)
// Si hay decimales conserva solamente la parte entera

module top_uart (

    input  wire CLOCK_50,
    input  wire RESET_N,
    input  wire UART_RX,
    output wire UART_TX

);

    wire reset;
    assign reset = ~RESET_N;

    // Datos recibidos por UART
    wire [7:0] rx_data;
    wire       rx_done;

    // Datos enviados por UART
    reg  [7:0] tx_data;
    reg        tx_start;
    wire       tx_busy;

    // Datos de la operacion
    reg [7:0] base;
    reg [3:0] numerator;

    // Control del modulo de potencia
    reg         power_start;
    wire [31:0] power_result;
    wire        power_done;
    wire        power_overflow;

    // Control del modulo de raiz
    reg        root_start;
    wire [7:0] root_result;
    wire       root_done;
    wire       root_exact;
    wire       root_out_of_range;

    // Resultado final
    reg [7:0] final_result;

    // Codigo de estado
    reg [7:0] status;

    // Estado actual
    reg [3:0] state;

    localparam WAIT_BASE       = 4'd0;
    localparam WAIT_NUMERATOR  = 4'd1;
    localparam START_POWER     = 4'd2;
    localparam WAIT_POWER      = 4'd3;
    localparam START_ROOT      = 4'd4;
    localparam WAIT_ROOT       = 4'd5;
    localparam SEND_STATUS     = 4'd6;
    localparam WAIT_STATUS_ON  = 4'd7;
    localparam WAIT_STATUS_OFF = 4'd8;
    localparam SEND_RESULT     = 4'd9;
    localparam WAIT_RESULT_ON  = 4'd10;
    localparam WAIT_RESULT_OFF = 4'd11;


    // Recibe datos desde la computadora
    uart_rx #(.CLK_FREQ(50000000), .BAUD_RATE(9600)) RX0 (.clk(CLOCK_50), .reset(reset), .rx(UART_RX), .data_out(rx_data), .data_valid(rx_done));

    // Envia datos hacia la computadora
    uart_tx #(.CLK_FREQ(50000000), .BAUD_RATE(9600)) TX0 (.clk(CLOCK_50), .reset(reset), .tx_start(tx_start), .data_in(tx_data), .tx(UART_TX), .busy(tx_busy));

    // Calcula base^numerador
    power_module POWER0 (.clk(CLOCK_50), .reset(reset), .start(power_start), .base(base), .exponent(numerator), .result(power_result), .done(power_done), .overflow(power_overflow));

    // Calcula la raiz cuadrada
    square_root_module ROOT0 (.clk(CLOCK_50), .reset(reset), .start(root_start), .radicand(power_result), .result(root_result), .done(root_done), .exact(root_exact), .out_of_range(root_out_of_range));


    always @(posedge CLOCK_50 or posedge reset) begin

        if (reset) begin

            base         <= 8'd0;
            numerator    <= 4'd0;

            power_start  <= 1'b0;
            root_start   <= 1'b0;

            tx_data      <= 8'd0;
            tx_start     <= 1'b0;

            final_result <= 8'd0;
            status       <= 8'd0;

            state        <= WAIT_BASE;

        end

        else begin

            // Señales de un solo ciclo
            tx_start    <= 1'b0;
            power_start <= 1'b0;
            root_start  <= 1'b0;


            case (state)

                WAIT_BASE: begin

                    // Primer byte: base
                    if (rx_done) begin
                        base  <= rx_data;
                        state <= WAIT_NUMERATOR;
                    end

                end


                WAIT_NUMERATOR: begin

                    // Segundo byte: numerador
                    if (rx_done) begin
                        numerator <= rx_data[3:0];
                        state     <= START_POWER;
                    end

                end


                START_POWER: begin

                    // Inicia base^numerador
                    power_start <= 1'b1;
                    state       <= WAIT_POWER;

                end


                WAIT_POWER: begin

                    // Espera la potencia
                    if (power_done) begin

                        if (power_overflow) begin

                            // La potencia supero 32 bits
                            status       <= 8'd1;
                            final_result <= 8'd0;
                            state        <= SEND_STATUS;

                        end

                        else begin

                            state <= START_ROOT;

                        end

                    end

                end


                START_ROOT: begin

                    // Inicia la raiz cuadrada
                    root_start <= 1'b1;
                    state      <= WAIT_ROOT;

                end


                WAIT_ROOT: begin

                    // Espera el resultado de la raiz
                    if (root_done) begin

                        if (root_out_of_range) begin

                            // El resultado supera 255
                            status       <= 8'd2;
                            final_result <= 8'd0;

                        end

                        else begin

                            // Resultado correcto
                            // Puede ser raiz exacta o parte entera
                            status       <= 8'd0;
                            final_result <= root_result;

                        end

                        state <= SEND_STATUS;

                    end

                end


                SEND_STATUS: begin

                    // Envia el codigo de estado
                    if (!tx_busy) begin
                        tx_data  <= status;
                        tx_start <= 1'b1;
                        state    <= WAIT_STATUS_ON;
                    end

                end


                WAIT_STATUS_ON: begin

                    if (tx_busy)
                        state <= WAIT_STATUS_OFF;

                end


                WAIT_STATUS_OFF: begin

                    if (!tx_busy)
                        state <= SEND_RESULT;

                end


                SEND_RESULT: begin

                    // Envia el resultado
                    if (!tx_busy) begin
                        tx_data  <= final_result;
                        tx_start <= 1'b1;
                        state    <= WAIT_RESULT_ON;
                    end

                end


                WAIT_RESULT_ON: begin

                    if (tx_busy)
                        state <= WAIT_RESULT_OFF;

                end


                WAIT_RESULT_OFF: begin

                    // Queda listo para una nueva operacion
                    if (!tx_busy)
                        state <= WAIT_BASE;

                end


                default: begin

                    state <= WAIT_BASE;

                end

            endcase

        end

    end

endmodule