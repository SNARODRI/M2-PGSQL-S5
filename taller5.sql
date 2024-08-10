--1.Crear una nueva cuenta bancaria
--Crea una nueva cuenta bancaria para un cliente, asignando un número de cuenta único y estableciendo un saldo inicial.
CREATE OR REPLACE PROCEDURE crear_cuenta_bancaria(
	v_cliente_id INTEGER,
	v_num_cuenta VARCHAR,
	v_tipo_cuenta VARCHAR,
	v_saldo NUMERIC,
	v_estado VARCHAR
)
LANGUAGE plpgsql
AS $$
	DECLARE
		BEGIN
			IF v_cliente_id = 0 THEN
				RAISE EXCEPTION 'El id del cliente no puede estar vacio';
			END IF;
 
			INSERT INTO Cuentas(cliente_id, numero_cuenta, tipo_cuenta, saldo, estado)
				VALUES (v_cliente_id, v_num_cuenta, v_tipo_cuenta, v_saldo, v_estado);
				RAISE NOTICE 'Cuenta creada con satisfacción';
		END;
$$;

CALL crear_cuenta_bancaria(1025487632, '556-889-665-557', 'AHORRO', 15000, 'ACTIVA');

--2.Actualizar la información del cliente
--Actualiza la información personal de un cliente, como dirección, teléfono y correo electrónico, basado en el ID del cliente.

CREATE OR REPLACE PROCEDURE actualizar_cliente(
	v_cliente_id INTEGER,
	v_direccion VARCHAR,
	v_telefono VARCHAR,
	v_mail VARCHAR
)
LANGUAGE plpgsql
AS $$
	DECLARE
		BEGIN
			IF v_cliente_id = 0 THEN
				RAISE EXCEPTION 'El id del cliente no puede estar vacio';
			END IF;
 
			Update Clientes 
				Set direccion = v_direccion, 
					telefono = v_telefono, 
					correo_electronico = v_mail
					Where cliente_id = v_cliente_id;
				RAISE NOTICE 'Cliente actualizado con exito';
		END;
$$;

CALL actualizar_cliente(1045869521, 'AVENUE', '+573208099472', 'prueba@prueba.com');
--3.Eliminar una cuenta bancaria
--Elimina una cuenta bancaria específica del sistema, incluyendo la eliminación de todas las transacciones asociadas.

CREATE OR REPLACE PROCEDURE eliminar_cuenta(
	v_numero_cuenta VARCHAR
)
LANGUAGE plpgsql
AS $$
	DECLARE
		BEGIN
			IF v_numero_cuenta = ' ' THEN
				RAISE EXCEPTION 'Numero de cuenta no puede estar vacio';
			END IF;
			Delete from Transacciones Where cuenta_id = v_numero_cuenta;
 			Delete from Cuentas Where numero_cuenta = v_numero_cuenta;
			
				RAISE NOTICE 'Cuenta y transacciones eliminadas con exito';
		END;
$$;

CALL eliminar_cuenta('000-333-444-444');
CALL eliminar_cuenta(' ');

--4.Transferir fondos entre cuentas
--Realiza una transferencia de fondos desde una cuenta a otra, asegurando que ambas cuentas se actualicen correctamente y se registre la transacción.

CREATE OR REPLACE PROCEDURE crear_trx_transferencia(
	v_num_cta_org VARCHAR,
	v_num_cta_dest VARCHAR,
	v_monto NUMERIC
)
LANGUAGE plpgsql
AS $$
	DECLARE
		v_saldo_org NUMERIC;
		v_saldo_dest NUMERIC;
		BEGIN
			IF v_num_cta_org = ' ' THEN
				RAISE EXCEPTION 'Numero de cuenta origen no puede estar vacio';
			END IF;
			
			IF v_num_cta_dest = ' '  THEN
				RAISE EXCEPTION 'Numero de cuenta destino no puede estar vacio';
			END IF;
			
			Select saldo Into v_saldo_org
			From Cuentas
			Where numero_cuenta = v_num_cta_org;
			
			Select saldo Into v_saldo_dest
			From Cuentas
			Where numero_cuenta = v_num_cta_dest;
			
			IF v_saldo_org < v_monto THEN
				RAISE EXCEPTION 'Saldo insuficiente para tranferencia';
			END IF;
			
			v_saldo_org = v_saldo_org - v_monto;
			v_saldo_dest = v_saldo_dest + v_monto;
				INSERT INTO Transacciones (cuenta_id, tipo_transaccion, monto, descripcion)
					VALUES (v_num_cta_org, 'TRANSFERENCIA', v_monto, 'PRINCIPAL');
				UPDATE Cuentas Set Saldo = v_saldo_org
					Where numero_cuenta = v_num_cta_org;
				UPDATE Cuentas Set Saldo = v_saldo_dest
					Where numero_cuenta = v_num_cta_dest;
			
			RAISE NOTICE 'Trx realizada de la cuenta %', v_saldo_org;
			RAISE NOTICE 'a la cuenta %', v_num_cta_dest;
			RAISE NOTICE 'nuevo saldo %', v_saldo_org;
		END;
$$;

CALL crear_trx_transferencia ('555-777-333-222', '555-222-111-999', 1000);

Select * from Transacciones;
Select * from Cuentas;

--5.Agregar una nueva transacción
--Registra una nueva transacción (depósito, retiro) en el sistema, actualizando el saldo de la cuenta asociada.

CREATE OR REPLACE PROCEDURE crear_trx(
	v_numero_cuenta VARCHAR,
	v_tipo_transaccion VARCHAR,
	v_monto NUMERIC
)
LANGUAGE plpgsql
AS $$
	DECLARE
		v_saldo NUMERIC;
		BEGIN
			IF v_numero_cuenta = ' ' THEN
				RAISE EXCEPTION 'Numero de cuenta no puede estar vacio';
			END IF;
			
			IF v_tipo_transaccion = ' '  THEN
				RAISE EXCEPTION 'Tipo de transacción no puede estar vacio';
			END IF;
			
			Select saldo Into v_saldo
			From Cuentas
			Where numero_cuenta = v_numero_cuenta;
			
			IF v_saldo < v_monto THEN
				RAISE EXCEPTION 'Saldo insuficiente';
			END IF;
			
			IF v_tipo_transaccion = 'DEPOSITO' THEN
			v_saldo = v_saldo + v_monto;
				INSERT INTO Transacciones (cuenta_id, tipo_transaccion, monto, descripcion)
					VALUES (v_numero_cuenta, v_tipo_transaccion, v_monto, 'PRINCIPAL');
				UPDATE Cuentas Set Saldo = v_saldo
					Where numero_cuenta = v_numero_cuenta;
			END IF;
			
			IF v_tipo_transaccion = 'RETIRO' Or v_tipo_transaccion = 'TRANSFERENCIA'THEN
			v_saldo = v_saldo - v_monto;
				INSERT INTO Transacciones (cuenta_id, tipo_transaccion, monto, descripcion)
					VALUES (v_numero_cuenta, v_tipo_transaccion, v_monto, 'PRINCIPAL');
				UPDATE Cuentas Set Saldo = v_saldo
					Where numero_cuenta = v_numero_cuenta;
			END IF;
			
			RAISE NOTICE 'Trx realizada a la cuenta %', v_numero_cuenta;
			RAISE NOTICE ' %', v_tipo_transaccion;
			RAISE NOTICE 'nuevo saldo %', v_saldo;
		END;
$$;

CALL crear_trx ('555-777-333-222', 'TRANSFERENCIA', 999);
Select * from Transacciones;
Select * from Cuentas;

--6.Calcular el saldo total de todas las cuentas de un cliente
--Calcula el saldo total combinado de todas las cuentas bancarias pertenecientes a un cliente específico.

CREATE OR REPLACE PROCEDURE saldo_cliente(
	v_cliente_id INTEGER
)
LANGUAGE plpgsql
AS $$
	DECLARE
		v_saldo_total NUMERIC;
		BEGIN
			IF v_cliente_id = 0 THEN
				RAISE EXCEPTION 'id cliente no puede ser cero(0)';
			END IF;
			Select sum(saldo) Into v_saldo_total
			From Cuentas
			Where cliente_id = v_cliente_id;
			
				RAISE NOTICE 'Cuenta consultada con exito %', v_saldo_total;
		END;
$$;

CALL saldo_cliente (1025487632);

Select sum(saldo) 
from Cuentas
where cliente_id=1025487632;

--7.Generar un reporte de transacciones para un rango de fechas
--Genera un reporte detallado de todas las transacciones realizadas en un rango de fechas específico.

CREATE OR REPLACE PROCEDURE reporte_trx(
	fecha_inicial VARCHAR,
	fecha_final VARCHAR
)
LANGUAGE plpgsql
AS $$
	DECLARE
		v_cuenta_id VARCHAR; 
		v_tipo_transaccion VARCHAR; 
		v_monto NUMERIC; 
		v_fecha_transaccion TIMESTAMP;
		BEGIN
			IF fecha_inicial = ' ' THEN
				RAISE EXCEPTION 'Fecha Inicial no puede estar vacio';
			END IF;
			IF fecha_final = ' ' THEN
				RAISE EXCEPTION 'Fecha Final no puede estar vacio';
			END IF;
			
			FOR v_cuenta_id, v_tipo_transaccion, v_monto, v_fecha_transaccion IN
			Select cuenta_id, tipo_transaccion, monto, fecha_transaccion 
				From Transacciones 
					Where CAST(fecha_transaccion As VARCHAR) 
					between fecha_inicial And fecha_final
			LOOP
				RAISE NOTICE 'Cuenta %', v_cuenta_id;
				RAISE NOTICE 'transacción %', v_tipo_transaccion;
				RAISE NOTICE 'monto %', v_monto;
				RAISE NOTICE 'fecha_trx %', v_fecha_transaccion;
			END LOOP;
		END;
$$;
CALL reporte_trx ('2023-01-01','2023-12-31');
Select cuenta_id, tipo_transaccion, monto, fecha_transaccion 
from Transacciones 
Where CAST(fecha_transaccion AS VARCHAR) between '2023-01-01' And '2023-12-31';