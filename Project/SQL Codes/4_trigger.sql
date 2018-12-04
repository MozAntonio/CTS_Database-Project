DROP TRIGGER IF EXISTS NotDeleteBolla1;
DROP TRIGGER IF EXISTS NotDeleteBolla2;
DROP TRIGGER IF EXISTS DeleteAziendaCliente;
DROP TRIGGER IF EXISTS DeleteAziendaRicevente;
DROP TRIGGER IF EXISTS InsertCliente;
DROP TRIGGER IF EXISTS UpdateCliente;
DROP TRIGGER IF EXISTS InsertCF;
DROP TRIGGER IF EXISTS InsertSigla;
DROP TRIGGER IF EXISTS InsertAzienda;
DROP TRIGGER IF EXISTS CostoEffettivo;
DROP TRIGGER IF EXISTS InsertPartner;
DROP TRIGGER IF EXISTS UpdatePartner;
DROP TRIGGER IF EXISTS InsertBolla;
DROP TRIGGER IF EXISTS UpdateBolla;
DROP TRIGGER IF EXISTS UpdateContainer;
DROP TRIGGER IF EXISTS UpdateMezzo;
DROP TRIGGER IF EXISTS UpdatePacco;



-- 1) Non si puo' eliminare LISTA se c'e' una BollaDiCarico!
DELIMITER |

CREATE TRIGGER NotDeleteBolla1
BEFORE DELETE ON LISTA
FOR EACH ROW
BEGIN
	DECLARE x INT;
	
	SELECT COUNT(*) INTO x FROM BOLLA_DI_CARICO BDC WHERE BDC.NumeroDoc=OLD.BollaDiCarico;
	
	IF (x > 0) THEN
		INSERT INTO LISTA SELECT * FROM LISTA LIMIT 1;
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La cancellazione della lista e'' fallita: Violazione del vincolo con bolla di carico.';
	END IF;
END |

DELIMITER ;


-- 2) Non si puo' eliminare RESPONSABILITA se c'e' una BollaDiCarico!
DELIMITER |

CREATE TRIGGER NotDeleteBolla2
BEFORE DELETE ON RESPONSABILITA
FOR EACH ROW
BEGIN
	DECLARE y INT;
	
	SELECT COUNT(*) INTO y FROM BOLLA_DI_CARICO BDC WHERE BDC.NumeroDoc=OLD.BollaDiCarico;
	
	IF (y > 0) THEN
		INSERT INTO RESPONSABILITA SELECT * FROM RESPONSABILITA LIMIT 1;
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La cancellazione della responsabilita e'' fallita: Violazione del vincolo con bolla di carico.';
	END IF;
END |

DELIMITER ;


-- 3) Trigger tra AZIENDA-RICENVENTE-CLIENTE: Se un Cliente viene cancellato e non e' anche un Ricevente (contemporeneamente), allora elimino l'AZIENDA!
DELIMITER |

CREATE TRIGGER DeleteAziendaCliente
AFTER DELETE ON CLIENTE
FOR EACH ROW
BEGIN
	DECLARE numClienti INT;
	
	SELECT COUNT(*) INTO numClienti FROM RICEVENTE R WHERE R.PartitaIVA=OLD.PartitaIVA AND R.SiglaPaese=OLD.SiglaPaese;
	
	IF (numClienti < 1) THEN
		DELETE FROM AZIENDA WHERE PartitaIVA=OLD.PartitaIVA AND SiglaPaese=OLD.SiglaPaese;
	END IF;
END |

DELIMITER ;


-- 4) Trigger tra AZIENDA-RICENVENTE-CLIENTE: Se un Ricevente viene cancellato e non e' anche un Cliente (contemporeneamente), allora elimino l'AZIENDA!
DELIMITER |

CREATE TRIGGER DeleteAziendaRicevente
AFTER DELETE ON RICEVENTE
FOR EACH ROW
BEGIN
	DECLARE numRiceventi INT;
	
	SELECT COUNT(*) INTO numRiceventi FROM CLIENTE C WHERE C.PartitaIVA=OLD.PartitaIVA AND C.SiglaPaese=OLD.SiglaPaese;
	
	IF (numRiceventi < 1) THEN
		DELETE FROM AZIENDA WHERE PartitaIVA=OLD.PartitaIVA AND SiglaPaese=OLD.SiglaPaese;
	END IF;
END |

DELIMITER ;


-- 5) Se durante l'inserimento di un Cliente lo stato risulta: "Convenzionato=False", il valore dello Sconto dovra' essere 0 (zero).
-- Mentre se il valore di Sconto supera la soglia massima posta a 50%, allora l'inserimento fallisce!
DELIMITER |

CREATE TRIGGER InsertCliente
BEFORE INSERT ON CLIENTE
FOR EACH ROW
BEGIN
	IF (NEW.Convenzionato = False) THEN
		SET NEW.Sconto=0;
	END IF;
	
	IF (NEW.Sconto > 49.9) THEN
		INSERT INTO CLIENTE SELECT * FROM CLIENTE LIMIT 1;
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Il valore di Sconto appena inserito supera il 50%.';
	END IF;
END |

DELIMITER ;


-- 6) Se durante l'aggiornamento di un Cliente il nuovo stato risulta: "Convenzionato=False", il valore del nuovo Sconto dovra' essere 0 (zero).
-- Mentre se il nuovo valore di Sconto supera la soglia massima posta a 50%, allora l'aggiornamento fallisce!
DELIMITER |

CREATE TRIGGER UpdateCliente
BEFORE UPDATE ON CLIENTE
FOR EACH ROW
BEGIN
	IF (NEW.Convenzionato = False) THEN
		SET NEW.Sconto=0;
	END IF;
	
	IF (NEW.Sconto > 49.9) THEN
		INSERT INTO CLIENTE SELECT * FROM CLIENTE LIMIT 1;
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Il valore di Sconto appena aggiornato supera il 50%.';
	END IF;
END |

DELIMITER ;


-- 7) Ad ogni inserimento di un nuovo CF di OPERAIO tale CF verra' memorizzato in UPPER-CASE nel DataBase!
CREATE TRIGGER InsertCF
BEFORE INSERT ON OPERAIO
FOR EACH ROW
SET NEW.CF=UCASE(NEW.CF);


-- 8) Ad ogni inserimento di una nuova Sigla di NAZIONE tale Sigla verra' memorizzata in UPPER-CASE nel DataBase!
CREATE TRIGGER InsertSigla
BEFORE INSERT ON NAZIONE
FOR EACH ROW
SET NEW.Sigla=UCASE(NEW.Sigla);


-- 9) Ad ogni inserimento di un nuovo Nome di AZIENDA tale Nome verra' memorizzata in UPPER-CASE nel DataBase!
CREATE TRIGGER InsertAzienda
BEFORE INSERT ON AZIENDA
FOR EACH ROW
SET NEW.Nome=UCASE(NEW.Nome);


-- 10) Dopo ogni inserimento di una nuova LISTA verra' aggiornato l'effettivo valore del CostoTotale della BollaDiCarico alla quale si riferisce!
DELIMITER |

CREATE TRIGGER CostoEffettivo
AFTER INSERT ON LISTA
FOR EACH ROW
BEGIN
	DECLARE costo DECIMAL(15,2);
	
	SET costo = CalcoloCostoTotale(NEW.BollaDiCarico);
	
	UPDATE BOLLA_DI_CARICO SET CostoTotale = costo WHERE NumeroDoc = NEW.BollaDiCarico;
END |

DELIMITER ;


-- 11) Prima di ogni inserimento di un nuovo PARTNER verra' verificato che InizioContratto e FineContratto rispettino le proprieta' di interesse!
DELIMITER |

CREATE TRIGGER InsertPartner
BEFORE INSERT ON PARTNER
FOR EACH ROW
BEGIN
	IF (NEW.FineContratto < NEW.InizioContratto) OR (DATE_ADD(NEW.InizioContratto, INTERVAL 90 DAY) > NEW.FineContratto) OR (NEW.FineContratto < CURRENT_DATE) THEN
		INSERT INTO PARTNER SELECT * FROM PARTNER LIMIT 1;
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La durata del contratto risulta inferiore a 3 mesi, oppure il contratto risulta gia'' scaduto.';
	END IF;
END |

DELIMITER ;


-- 12) Prima di ogni aggiornamento di un PARTNER verra' verificato che InizioContratto e FineContratto rispettino le proprieta' di interesse.
-- In caso contrario le modifiche di tali date saranno rese vane.
DELIMITER |

CREATE TRIGGER UpdatePartner
BEFORE UPDATE ON PARTNER
FOR EACH ROW
BEGIN
	-- IF (NEW.FineContratto < NEW.InizioContratto) OR (DATE_ADD(NEW.InizioContratto, INTERVAL 90 DAY) > NEW.FineContratto) OR (NEW.FineContratto < CURRENT_DATE) THEN
	IF (NEW.FineContratto < NEW.InizioContratto) OR (DATEDIFF(NEW.FineContratto, NEW.InizioContratto) < 90) OR (NEW.FineContratto < CURRENT_DATE) THEN
		SET NEW.FineContratto=OLD.FineContratto;
		SET NEW.InizioContratto=OLD.InizioContratto;
	END IF;
END |

DELIMITER ;


-- 13) Prima di ogni inserimento di una nuova BOLLA_DI_CARICO verra' verificato che i campi DataEmissione, DataInvio, e DataConsegna rispettino le proprieta' di interesse!
-- In caso contrario il nuovo inserimento fallira'.
DELIMITER |

CREATE TRIGGER InsertBolla
BEFORE INSERT ON BOLLA_DI_CARICO
FOR EACH ROW
BEGIN
	IF (NEW.DataEmissione > NEW.DataInvio) OR (NEW.DataEmissione > NEW.DataConsegna) OR (NEW.DataInvio > NEW.DataConsegna) THEN
		INSERT INTO BOLLA_DI_CARICO SELECT * FROM BOLLA_DI_CARICO LIMIT 1;
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Inserimento fallito! Si ricorda che: DataEmissione <= DataInvio <= DataConsegna.';
	END IF;
END |

DELIMITER ;


-- 14) Prima di ogni aggiornamento di una BOLLA_DI_CARICO verra' verificato che i campi DataEmissione, DataInvio, e DataConsegna rispettino le proprieta' di interesse!
-- In caso contrario le modifiche di tali date saranno rese vane.
DELIMITER |

CREATE TRIGGER UpdateBolla
BEFORE UPDATE ON BOLLA_DI_CARICO
FOR EACH ROW
BEGIN
	IF (NEW.DataEmissione > NEW.DataInvio) OR (NEW.DataEmissione > NEW.DataConsegna) OR (NEW.DataInvio > NEW.DataConsegna) THEN
		SET NEW.DataEmissione=OLD.DataEmissione;
		SET NEW.DataInvio=OLD.DataInvio;
		SET NEW.DataConsegna=OLD.DataConsegna;
	END IF;
END |

DELIMITER ;


-- 15) Prima di ogni aggiornamento effettuato sulla tabella CONTAINER, se i campi: 'VolumeInterno' e/o 'PesoMassimo' vengono modificati, tali modifiche devono 
-- risultare vane. Questo e' necessario per mantenere l'integrita' del DataBase, e quindi solamente un DBA puo', con le dovute precauzioni, effettuare 
-- operazioni di questo tipo!
DELIMITER |

CREATE TRIGGER UpdateContainer
BEFORE UPDATE ON CONTAINER
FOR EACH ROW
BEGIN
	IF (NEW.VolumeInterno <> OLD.VolumeInterno) OR (NEW.PesoMassimo <> OLD.PesoMassimo) THEN
		SET NEW.VolumeInterno=OLD.VolumeInterno;
		SET NEW.PesoMassimo=OLD.PesoMassimo;
	END IF;
END |

DELIMITER ;


-- 16) Prima di ogni aggiornamento effettuato sulla tabella MEZZO_DI_TRASPORTO, se il campo: 'Container' viene modificato, tale modifica deve risultare vana.
-- Questo e' necessario per mantenere l'integrita' del DataBase, e quindi solamente un DBA puo', con le dovute precauzioni, effettuare un'operazione di questo tipo!
DELIMITER |

CREATE TRIGGER UpdateMezzo
BEFORE UPDATE ON MEZZO_DI_TRASPORTO
FOR EACH ROW
BEGIN
	IF (NEW.Container <> OLD.Container) THEN
		SET NEW.Container=OLD.Container;
	END IF;
END |

DELIMITER ;


-- 17) Prima di ogni aggiornamento effettuato sulla tabella PACCO, se i campi: 'Larghezza', 'Lunghezza', 'Altezza', e/o 'Peso' vengono modificati, tali modifiche 
-- devono risultare vane. Questo e' necessario per mantenere l'integrita' del DataBase, e quindi solamente un DBA puo', con le dovute precauzioni, 
-- effettuare operazioni di questo tipo!
DELIMITER |

CREATE TRIGGER UpdatePacco
BEFORE UPDATE ON PACCO
FOR EACH ROW
BEGIN
	IF (NEW.Larghezza <> OLD.Larghezza) OR (NEW.Lunghezza <> OLD.Lunghezza) OR (NEW.Altezza <> OLD.Altezza) OR (NEW.Peso <> OLD.Peso) THEN
		SET NEW.Larghezza=OLD.Larghezza;
		SET NEW.Lunghezza=OLD.Lunghezza;
		SET NEW.Altezza=OLD.Altezza;
		SET NEW.Peso=OLD.Peso;
	END IF;
END |

DELIMITER ;


