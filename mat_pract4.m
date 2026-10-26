clear
clc

% Puerto del ESP32
PORT = "COM5";      % Cambiar por el puerto correspondiente
BAUD = 9600;

% Abre la comunicacion serial
s = serialport(PORT, BAUD);

% Espera a que el ESP32 se estabilice
pause(2);

% Limpia datos anteriores
flush(s);

disp("Comunicacion UART iniciada");
disp("Operacion: base^(numerador/2)");
disp("El resultado se muestra como numero entero");
disp(" ");

while true

    % Datos de entrada
    base = input('Ingrese la base (0 a 255): ');
    numerador = input('Ingrese el numerador (0 a 15): ');

    % Verifica la base
    if base < 0 || base > 255
        disp("Base fuera de rango");
        disp(" ");
        continue;
    end

    % Verifica el numerador
    if numerador < 0 || numerador > 15
        disp("Numerador fuera de rango");
        disp(" ");
        continue;
    end

    % Limpia posibles datos anteriores
    flush(s);

    % Envia dos bytes: base y numerador
    write(s, [uint8(base) uint8(numerador)], "uint8");

    fprintf("\nOperacion enviada: %d^(%d/2)\n", base, numerador);

    % Espera la respuesta de la FPGA
    tiempo_inicio = tic;

    while s.NumBytesAvailable < 2

        % Tiempo maximo de espera
        if toc(tiempo_inicio) > 3
            break;
        end

    end

    % Lee los dos bytes de respuesta
    if s.NumBytesAvailable >= 2

        respuesta = read(s, 2, "uint8");

        status = respuesta(1);
        resultado = respuesta(2);

        % Interpreta el codigo recibido
        if status == 0

            fprintf("Resultado entero: %d\n\n", resultado);

        elseif status == 1

            disp("Error: la potencia intermedia supera 32 bits");
            disp(" ");

        elseif status == 2

            disp("Error: el resultado final supera 255");
            disp(" ");

        else

            disp("Error desconocido");
            disp(" ");

        end

    else

        disp("No se recibio respuesta de la FPGA");
        disp(" ");

    end

end