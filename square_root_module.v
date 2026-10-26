// Modulo para calcular raiz cuadrada entera
// Si la raiz tiene decimales, conserva solamente la parte entera

module square_root_module (

    input  wire        clk,
    input  wire        reset,
    input  wire        start,

    input  wire [31:0] radicand,

    output reg  [7:0]  result,
    output reg         done,
    output reg         exact,
    output reg         out_of_range

);

    // Guarda el numero al que se le calculara la raiz
    reg [31:0] radicand_reg;

    // Valor que se prueba como posible raiz
    reg [7:0] candidate;

    // Indica si el modulo esta realizando el calculo
    reg active;

    // Cuadrado del candidato actual
    wire [15:0] square;

    assign square = candidate * candidate;


    always @(posedge clk or posedge reset) begin

        if (reset) begin

            radicand_reg <= 32'd0;
            candidate    <= 8'd0;
            result       <= 8'd0;
            done         <= 1'b0;
            exact        <= 1'b0;
            out_of_range <= 1'b0;
            active       <= 1'b0;

        end

        else begin

            // done solo dura un ciclo
            done <= 1'b0;


            // Inicia un nuevo calculo
            if (start && !active) begin

                radicand_reg <= radicand;
                candidate    <= 8'd0;
                result       <= 8'd0;
                exact        <= 1'b0;
                out_of_range <= 1'b0;

                // La raiz es mayor que 255
                if (radicand > 32'd65025) begin

                    out_of_range <= 1'b1;
                    done         <= 1'b1;
                    active       <= 1'b0;

                end

                else begin

                    active <= 1'b1;

                end

            end


            // Prueba un candidato en cada ciclo
            else if (active) begin

                // Se encontro una raiz exacta
                if (square == radicand_reg) begin

                    result <= candidate;
                    exact  <= 1'b1;
                    done   <= 1'b1;
                    active <= 1'b0;

                end

                // Si se supera el radicando,
                // guarda el candidato anterior
                else if (square > radicand_reg) begin

                    result <= candidate - 8'd1;
                    exact  <= 1'b0;
                    done   <= 1'b1;
                    active <= 1'b0;

                end

                // Prueba el siguiente numero
                else begin

                    candidate <= candidate + 8'd1;

                end

            end

        end

    end

endmodule