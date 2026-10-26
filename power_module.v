// Modulo para calcular base^exponente
// Realiza la potencia mediante multiplicaciones sucesivas

module power_module (

    input  wire        clk,
    input  wire        reset,
    input  wire        start,

    input  wire [7:0]  base,
    input  wire [3:0]  exponent,

    output reg  [31:0] result,
    output reg         done,
    output reg         overflow

);

    // Guarda la base mientras se realiza el calculo
    reg [7:0] base_reg;

    // Guarda el exponente mientras se realiza el calculo
    reg [3:0] exponent_reg;

    // Cuenta cuantas multiplicaciones se han realizado
    reg [3:0] count;

    // Indica si el modulo esta calculando
    reg active;

    // Producto temporal de 40 bits
    // Se usa para detectar si el resultado supera los 32 bits
    wire [39:0] product;

    // Multiplica el resultado actual por la base
    assign product = result * base_reg;


    always @(posedge clk or posedge reset) begin

        if (reset) begin

            // Valores iniciales
            result       <= 32'd1;
            base_reg     <= 8'd0;
            exponent_reg <= 4'd0;
            count        <= 4'd0;
            active       <= 1'b0;
            done         <= 1'b0;
            overflow     <= 1'b0;

        end

        else begin

            // done solo se activa durante un ciclo de reloj
            done <= 1'b0;


            // Inicia un nuevo calculo cuando start vale 1
            // y el modulo no esta ocupado
            if (start && !active) begin

             
                base_reg     <= base;
                exponent_reg <= exponent;

              
                count        <= 4'd0;
                result       <= 32'd1;
                overflow     <= 1'b0;

                // Si el exponente es cero, el resultado es 1
                if (exponent == 4'd0) begin

                    result <= 32'd1;
                    done   <= 1'b1;
                    active <= 1'b0;

                end

                else begin

                    // Comienza el proceso de multiplicacion
                    active <= 1'b1;

                end

            end


            // Mientras active sea 1 se realiza una multiplicacion
            // en cada ciclo de reloj
            else if (active) begin

                // Si los bits superiores del producto son distintos de cero,
                // significa que el resultado ya no cabe en 32 bits
                if (product[39:32] != 8'd0) begin

                    overflow <= 1'b1;
                    done     <= 1'b1;
                    active   <= 1'b0;

                end

                else begin

                    // Guarda el nuevo resultado
                    result <= product[31:0];

                    // Incrementa el numero de multiplicaciones realizadas
                    count <= count + 4'd1;

                    // Cuando se completa el numero de multiplicaciones
  
                    if (count == exponent_reg - 4'd1) begin

                        done   <= 1'b1;
                        active <= 1'b0;

                    end

                end

            end

        end

    end

endmodule