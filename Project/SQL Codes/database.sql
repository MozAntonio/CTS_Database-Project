-- CREATE TABLE:

-- SET FOREIGN_KEY_CHECKS=0;


DROP TABLE IF EXISTS NAZIONE;
DROP TABLE IF EXISTS CONTAINER;
DROP TABLE IF EXISTS MEZZO_DI_TRASPORTO;
DROP TABLE IF EXISTS PARTNER;
DROP TABLE IF EXISTS SPEDIZIONE;
DROP TABLE IF EXISTS PACCO;
DROP TABLE IF EXISTS OPERAIO;
DROP TABLE IF EXISTS AZIENDA;
DROP TABLE IF EXISTS CLIENTE;
DROP TABLE IF EXISTS RICEVENTE;
DROP TABLE IF EXISTS DEPOSITO;
DROP TABLE IF EXISTS TELEFONO;
DROP TABLE IF EXISTS BOLLA_DI_CARICO;
DROP TABLE IF EXISTS FORNITURA;
DROP TABLE IF EXISTS LISTA;
DROP TABLE IF EXISTS RESPONSABILITA;
DROP TABLE IF EXISTS DELEGA;



-- TABELLE DERIVANTI DALLE ENTITA':
CREATE TABLE NAZIONE(
	Sigla CHAR(3) NOT NULL,
	Nome VARCHAR(30) NOT NULL,
	
	UNIQUE (Nome),
	PRIMARY KEY (Sigla)
)ENGINE=INNODB;

CREATE TABLE CONTAINER(
	Dimensione ENUM('Piccolo','Medio','Grande') NOT NULL,
	Materiale VARCHAR(15) NOT NULL,
	VolumeInterno DECIMAL(12,2) NOT NULL,
	Tara DECIMAL(10,2) NOT NULL,
	PesoMassimo DECIMAL(10,2) NOT NULL,
	Costo DECIMAL(13,2) NOT NULL,
	Colore VARCHAR(12),
	
	UNIQUE (VolumeInterno),
	PRIMARY KEY (Dimensione)
)ENGINE=INNODB;

CREATE TABLE MEZZO_DI_TRASPORTO(
	Categoria ENUM('Camion','Nave','Aereo') NOT NULL,
	Capacita INTEGER(3) NOT NULL,
	CostoBase DECIMAL(13,2) NOT NULL,
	Container ENUM('Piccolo','Medio','Grande') NOT NULL,
	
	UNIQUE (Container),
	PRIMARY KEY (Categoria),
	
	FOREIGN KEY (Container) REFERENCES CONTAINER(Dimensione)
		ON DELETE RESTRICT   -- Impedisce l'eliminazione di container se ci sono mezzi di trasporto.
)ENGINE=INNODB;

CREATE TABLE PARTNER(
	Nome VARCHAR(50) NOT NULL,
	InizioContratto DATE NOT NULL, -- Espresso nel formato "AAAA-MM-GG"
	FineContratto DATE NOT NULL, -- Espresso nel formato "AAAA-MM-GG"
	Slogan VARCHAR(100),
	PRIMARY KEY (Nome)
)ENGINE=INNODB;

CREATE TABLE SPEDIZIONE(
	LuogoDestinazione VARCHAR(20) NOT NULL,
	Tempo DECIMAL(5,2) NOT NULL, -- Espresso in ORE
	Distanza INTEGER(10) NOT NULL, -- Espressa in KM
	Mezzo ENUM('Camion','Nave','Aereo') NOT NULL,
	PRIMARY KEY (LuogoDestinazione, Mezzo),
	
	FOREIGN KEY (Mezzo) REFERENCES MEZZO_DI_TRASPORTO(Categoria)
		ON DELETE RESTRICT   -- Impedisce l'eliminazione di mezzo di trasporto se ci sono spedizioni.
)ENGINE=INNODB;

CREATE TABLE PACCO(
	Tipo VARCHAR(10) NOT NULL,
	Materiale VARCHAR(15) NOT NULL,
	Larghezza DECIMAL(10,2) NOT NULL,
	Lunghezza DECIMAL(10,2) NOT NULL,
	Altezza DECIMAL(10,2) NOT NULL,
	Peso DECIMAL(8,2) NOT NULL,
	
	CONSTRAINT dimensioni UNIQUE (Larghezza, Lunghezza, Altezza),
	PRIMARY KEY (Tipo)
)ENGINE=INNODB;

CREATE TABLE OPERAIO(
	CF CHAR(16) NOT NULL,
	Cognome VARCHAR(15) NOT NULL,
	Nome VARCHAR(20) NOT NULL,
	NazioneNascita CHAR(3) NOT NULL,
	
	CONSTRAINT nominativo UNIQUE (Nome, Cognome, NazioneNascita),
	PRIMARY KEY (CF),
	
	FOREIGN KEY (NazioneNascita) REFERENCES NAZIONE(Sigla)
		ON DELETE RESTRICT ON UPDATE CASCADE   -- Impedisce l'eliminazione di nazione se ci sono operai, e se nazione viene aggiornata si aggiornano anche gli operai.
)ENGINE=INNODB;

CREATE TABLE AZIENDA(
	PartitaIVA VARCHAR(15) NOT NULL,
	Nome VARCHAR(50) NOT NULL,
	Via VARCHAR(50) NOT NULL,
	Civico SMALLINT(5) NOT NULL,
	CAP CHAR(5) NOT NULL,
	Citta VARCHAR(40) NOT NULL,
	E_Mail VARCHAR(50) NOT NULL,
	SiglaPaese CHAR(3) NOT NULL,
	
	CONSTRAINT indirizzo UNIQUE (Via, Civico, CAP, Citta, SiglaPaese),
	UNIQUE (E_Mail),
	PRIMARY KEY (PartitaIVA, SiglaPaese),
	
	FOREIGN KEY (SiglaPaese) REFERENCES NAZIONE(Sigla)
		ON DELETE RESTRICT ON UPDATE CASCADE   -- Impedisce l'eliminazione di nazione se ci sono aziende, e se nazione viene aggiornata si aggiornano anche le aziende.
)ENGINE=INNODB;

-- Trigger tra AZIENDA-RICENVENTE-CLIENTE: Se un Cliente viene cancellato e non e' anche un Ricevente (contemporeneamente), allora elimino l'AZIENDA!!!
-- (Lo stesso vale per l'eliminazione di un Ricevente che non e' anche un Cliente, se non lo e' allora elimino l'AZIENDA)!

CREATE TABLE CLIENTE(
	Convenzionato BOOLEAN DEFAULT false, -- TRUE se e' convenzionato, e FALSE se non lo e'!
	Sconto DECIMAL(3,1) DEFAULT 0, -- Quantita' espressa in percentuale (per ovvi motivi non e' possibile avere uno sconto del 100%)!
	PartitaIVA VARCHAR(15) NOT NULL,
	SiglaPaese CHAR(3) NOT NULL,
	PRIMARY KEY (PartitaIVA, SiglaPaese),
	
	FOREIGN KEY (PartitaIVA, SiglaPaese) REFERENCES AZIENDA(PartitaIVA, SiglaPaese)
		ON DELETE RESTRICT ON UPDATE CASCADE   -- Impedisce l'eliminazione di azienda se ci sono clienti, e se azienda viene aggiornata si aggiornano anche i clienti.
)ENGINE=INNODB;

CREATE TABLE RICEVENTE(
	PartitaIVA VARCHAR(15) NOT NULL,
	SiglaPaese CHAR(3) NOT NULL,
	PRIMARY KEY (PartitaIVA, SiglaPaese),
	
	FOREIGN KEY (PartitaIVA, SiglaPaese) REFERENCES AZIENDA(PartitaIVA, SiglaPaese)
		ON DELETE RESTRICT ON UPDATE CASCADE   -- Impedisce l'eliminazione di azienda se ci sono riceventi, e se azienda viene aggiornata si aggiornano anche i riceventi.
)ENGINE=INNODB;

CREATE TABLE DEPOSITO(
	Via VARCHAR(50) NOT NULL,
	Civico SMALLINT(5) NOT NULL,
	CAP CHAR(5) NOT NULL,
	Citta VARCHAR(40) NOT NULL,
	Paese CHAR(3) NOT NULL,
	Ricevente VARCHAR(15) NOT NULL,
	NazioneProprietario CHAR(3) NOT NULL,
	NumeroPiani SMALLINT(2),
	
	CONSTRAINT aziendaRicevente UNIQUE (Ricevente, NazioneProprietario),
	PRIMARY KEY (Via, Civico, CAP, Citta, Paese),
	
	FOREIGN KEY (Ricevente, NazioneProprietario) REFERENCES RICEVENTE(PartitaIVA, SiglaPaese)
		ON DELETE CASCADE ON UPDATE CASCADE,   -- Se si elimina o modifica un ricevente, cio' verra' propagato anche a deposito.
	FOREIGN KEY (Paese) REFERENCES NAZIONE(Sigla)
		ON DELETE RESTRICT ON UPDATE CASCADE   -- Impedisce l'eliminazione di nazione se ci sono depositi, e se nazione viene aggiornata si aggiornano anche i depositi.
)ENGINE=INNODB;

CREATE TABLE TELEFONO(
	Prefisso CHAR(4) NOT NULL,
	Numero CHAR(10) NOT NULL,
	PartitaIVA VARCHAR(15) NOT NULL,
	NazionePossessore CHAR(3) NOT NULL,
	PRIMARY KEY (Prefisso, Numero),
	
	FOREIGN KEY (PartitaIVA, NazionePossessore) REFERENCES AZIENDA(PartitaIVA, SiglaPaese)
		ON DELETE CASCADE ON UPDATE CASCADE   -- Se si aggiorna o modifica un'azienda, cio' verra' propagato anche a telefono.
)ENGINE=INNODB;

CREATE TABLE BOLLA_DI_CARICO(
	NumeroDoc VARCHAR(20) NOT NULL,
	Corriere VARCHAR(35) NOT NULL,
	CostoTotale DECIMAL(15,2) DEFAULT 0,
	DataConsegna DATE NOT NULL, -- Espresso nel formato "AAAA-MM-GG"
	DataInvio DATE NOT NULL, -- Espresso nel formato "AAAA-MM-GG"
	DataEmissione DATE NOT NULL, -- Espresso nel formato "AAAA-MM-GG"
	MetodoPagamento VARCHAR(10) NOT NULL,
	Nota VARCHAR(256),
	Ricevente VARCHAR(15) NOT NULL,
	PaeseRicevente CHAR(3) NOT NULL,
	Cliente VARCHAR(15) NOT NULL,
	PaeseCliente CHAR(3) NOT NULL,
	Destinazione VARCHAR(20) NOT NULL,
	Mezzo ENUM('Camion','Nave','Aereo') NOT NULL,
	PRIMARY KEY (NumeroDoc),
	
	FOREIGN KEY (Cliente, PaeseCliente) REFERENCES CLIENTE(PartitaIVA, SiglaPaese)
		ON DELETE RESTRICT ON UPDATE CASCADE,   -- Impedisce l'eliminazione di cliente se ci sono bolle di carico, e se cliente viene aggiornato si aggiornano anche le bolle di carico.
	FOREIGN KEY (Ricevente, PaeseRicevente) REFERENCES RICEVENTE(PartitaIVA, SiglaPaese)
		ON DELETE RESTRICT ON UPDATE CASCADE,   -- Impedisce l'eliminazione di ricevente se ci sono bolle di carico, e se ricevente viene aggiornato si aggiornano anche le bolle di carico.
	FOREIGN KEY (Destinazione, Mezzo) REFERENCES SPEDIZIONE(LuogoDestinazione, Mezzo)
		ON DELETE RESTRICT ON UPDATE CASCADE   -- Impedisce l'eliminazione di spedizione se ci sono bolle di carico, e se spedizione viene aggiornata si aggiornano anche le bolle di carico.
)ENGINE=INNODB;


-- TABELLE DERIVANTI DA RELAZIONI N-N:
CREATE TABLE FORNITURA(
	Partner VARCHAR(50) NOT NULL,
	Mezzo ENUM('Camion','Nave','Aereo') NOT NULL,
	PRIMARY KEY (Partner, Mezzo),
	
	FOREIGN KEY (Partner) REFERENCES PARTNER(Nome)
		ON DELETE CASCADE ON UPDATE CASCADE,   -- Se si elimina o modifica un partner, cio' verra' propagato anche a fornitura.
	FOREIGN KEY (Mezzo) REFERENCES MEZZO_DI_TRASPORTO(Categoria)
)ENGINE=INNODB;

CREATE TABLE LISTA(
	BollaDiCarico VARCHAR(20) NOT NULL,
	Pacco VARCHAR(10) NOT NULL,
	Elementi INTEGER(6) NOT NULL,
	PRIMARY KEY (BollaDiCarico, Pacco),
	
	-- TRIGGER: Non si puo' eliminare LISTA se c'e' una BollaDiCarico!
	
	FOREIGN KEY (BollaDiCarico) REFERENCES BOLLA_DI_CARICO(NumeroDoc)
		ON DELETE CASCADE ON UPDATE CASCADE,   -- Se si elimina o modifica una bolla di carico, cio' verra' propagato anche a lista.
	FOREIGN KEY (Pacco) REFERENCES PACCO(Tipo)
		ON DELETE RESTRICT   -- Impedisce l'eliminazione di pacco se ci sono liste.
)ENGINE=INNODB;

CREATE TABLE RESPONSABILITA(
	BollaDiCarico VARCHAR(20) NOT NULL,
	Operaio CHAR(16) NOT NULL,
	PRIMARY KEY (BollaDiCarico, Operaio),
	
	-- TRIGGER: Non si puo' eliminare RESPONSABILITA se c'e' una BollaDiCarico!
	
	FOREIGN KEY (BollaDiCarico) REFERENCES BOLLA_DI_CARICO(NumeroDoc)
		ON DELETE CASCADE ON UPDATE CASCADE,   -- Se si elimina o modifica una bolla di carico, cio' verra' propagato anche a responsabilita.
	FOREIGN KEY (Operaio) REFERENCES OPERAIO(CF)
		ON DELETE RESTRICT ON UPDATE CASCADE   -- Impedisce l'eliminazione di operaio se ci sono responsabilita, e se operaio viene aggiornato si aggiornano anche le responsabilita.
)ENGINE=INNODB;

CREATE TABLE DELEGA(
	Delegato VARCHAR(15) NOT NULL,
	SiglaDelegato CHAR(3) NOT NULL,
	Delegante VARCHAR(15) NOT NULL,
	SiglaDelegante CHAR(3) NOT NULL,
	PRIMARY KEY (Delegato, SiglaDelegato, Delegante, SiglaDelegante),
	
	FOREIGN KEY (Delegato, SiglaDelegato) REFERENCES CLIENTE(PartitaIVA, SiglaPaese)
		ON DELETE CASCADE ON UPDATE CASCADE,   -- Se si elimina o modifica un cliente, cio' verra' propagato anche a delegato di delega.
	FOREIGN KEY (Delegante, SiglaDelegante) REFERENCES CLIENTE(PartitaIVA, SiglaPaese)
		ON DELETE CASCADE ON UPDATE CASCADE   -- Se si elimina o modifica un cliente, cio' verra' propagato anche a delegante di delega.
)ENGINE=INNODB;



-- SET FOREIGN_KEY_CHECKS=1;




-- FUNCTION:

DROP FUNCTION IF EXISTS CalcoloNumPacco;
DROP FUNCTION IF EXISTS NumContainer;
DROP FUNCTION IF EXISTS NumMezzi;
DROP FUNCTION IF EXISTS CalcoloCostoTotale;
DROP FUNCTION IF EXISTS DimContainer;
DROP FUNCTION IF EXISTS NumeroTelefono;
DROP FUNCTION IF EXISTS IndirizzoConsegnaRicevente;



-- 1) Funzione che, forniti un NumeroDoc di BOLLA_DI_CARICO e un Tipo di PACCO, restituisce il numero di Elementi relativi a tale bolla.
DELIMITER |

CREATE FUNCTION CalcoloNumPacco(numBolla VARCHAR(20), tipoPacco ENUM('Cassa', 'Barile', 'Scatolone', 'Sacco')) RETURNS INT
BEGIN
	DECLARE numPacchi INT;
	DECLARE counter INT;
	
	SELECT Elementi, COUNT(*)
	INTO numPacchi, counter
	FROM LISTA
	WHERE BollaDiCarico=numBolla AND Pacco=tipoPacco;
	
	IF (counter = 0) THEN
		SET numPacchi = 0;
	END IF;
	
	RETURN numPacchi;
END |

DELIMITER ;


-- 2) Funzione che, forniti un NumeroDoc di BOLLA_DI_CARICO e una Dimensione di CONTAINER, restituisce il numero di container necessari al fine di 
-- trasportare tutti i pacchi di merce del cliente intestatario della bolla in esame.
DELIMITER |

CREATE FUNCTION NumContainer(numBolla VARCHAR(20), container ENUM('Piccolo', 'Medio', 'Grande')) RETURNS INT
BEGIN
	DECLARE numCasse DECIMAL(10,2);
	DECLARE numBarili DECIMAL(10,2);
	DECLARE numScatoloni DECIMAL(10,2);
	DECLARE numSacchi DECIMAL(10,2);
	
	DECLARE sommaPacchi DECIMAL(10,2);
	
	DECLARE numCont INT;
	DECLARE resto INT;
	
	SET numCasse = CalcoloNumPacco(numBolla, 'Cassa') * 1;
	SET numBarili = CalcoloNumPacco(numBolla, 'Barile') * (1/2);
	SET numScatoloni = CalcoloNumPacco(numBolla, 'Scatolone') * (1/4);
	SET numSacchi = CalcoloNumPacco(numBolla, 'Sacco') * (1/10);
	
	SET sommaPacchi = numCasse + numBarili + numScatoloni + numSacchi;
	
	CASE
		WHEN container='Piccolo' THEN SET numCont = FLOOR(sommaPacchi/12), resto = sommaPacchi%12;
		WHEN container='Medio' THEN SET numCont = FLOOR(sommaPacchi/24), resto = sommaPacchi%24;
		ELSE SET numCont = FLOOR(sommaPacchi/30), resto = sommaPacchi%30;
	END CASE;
	
	IF (resto <> 0) THEN
		SET numCont = numCont + 1;
	END IF;
	
	RETURN numCont;
END |

DELIMITER ;


-- 3) Funzione che, forniti un NumeroDiContainer e una Categoria di MEZZO_DI_TRASPORTO, restituisce il numero di mezzi (della categoria in esame) necessari
-- al fine del trasporto del numero di container specificato.
DELIMITER |

CREATE FUNCTION NumMezzi(totContainer INT, catMezzo ENUM('Camion', 'Nave', 'Aereo')) RETURNS INT(3)
BEGIN
	DECLARE capacity INT;
	
	DECLARE nMezzi INT(3);
	DECLARE resto INT;
	
	SELECT Capacita INTO capacity FROM MEZZO_DI_TRASPORTO WHERE Categoria=catMezzo;
	
	SET nMezzi = FLOOR(totContainer/capacity);
	SET resto = totContainer%capacity;
	
	IF (resto <> 0) THEN
		SET nMezzi = nMezzi + 1;
	END IF;
	
	RETURN nMezzi;
END |

DELIMITER ;


-- 4) Funzione che, ricevendo in input una Categoria di MEZZO_DI_TRASPORTO, fornisce la Dimensione del CONTAINER che tale mezzo può trasportare.
DELIMITER |

CREATE FUNCTION DimContainer(catMezzo ENUM('Camion', 'Nave', 'Aereo')) RETURNS ENUM('Piccolo', 'Medio', 'Grande')
BEGIN
	DECLARE dimCont ENUM('Piccolo', 'Medio', 'Grande');
	
	CASE
		WHEN catMezzo='Camion' THEN SET dimCont='Piccolo';
		WHEN catMezzo='Aereo' THEN SET dimCont='Medio';
		ELSE SET dimCont='Grande';
	END CASE;
	
	RETURN dimCont;
END |

DELIMITER ;


-- 5) Funzione che, dato in input un NumeroDoc di una BOLLA_DI_CARICO, calcola il CostoTotale di tale bolla, in base ai dati ad essa relativi.
DELIMITER |

CREATE FUNCTION CalcoloCostoTotale(numBolla VARCHAR(20)) RETURNS DECIMAL(15,2)
BEGIN
	DECLARE catMezzo ENUM('Camion', 'Nave', 'Aereo');
	
	DECLARE costoContainer DECIMAL(13,2);
	DECLARE costoMezzo DECIMAL(13,2);
	
	DECLARE distance INT(10);
	
	DECLARE totContainer INT;
	DECLARE totMezzi INT(3);
	
	DECLARE imponibile DECIMAL(15,2);
	DECLARE scontoCliente DECIMAL(3,1);
	
	SELECT Mezzo INTO catMezzo FROM BOLLA_DI_CARICO BDC WHERE BDC.NumeroDoc=numBolla;
	
	SELECT Costo INTO costoContainer FROM CONTAINER WHERE Dimensione=DimContainer(catMezzo);
	SELECT CostoBase INTO costoMezzo FROM MEZZO_DI_TRASPORTO WHERE Categoria=catMezzo;
	
	SELECT Distanza INTO distance FROM SPEDIZIONE WHERE (Mezzo = catMezzo) AND (LuogoDestinazione IN
		(SELECT Destinazione FROM BOLLA_DI_CARICO WHERE NumeroDoc = numBolla));
	
	SET totContainer = NumContainer(numBolla, DimContainer(catMezzo));
	SET totMezzi = NumMezzi(totContainer, catMezzo);
	
	SET imponibile = (totContainer * costoContainer) + (totMezzi * costoMezzo) + ((distance * 0.05) * totMezzi);
	
	SELECT Sconto INTO scontoCliente FROM CLIENTE C JOIN BOLLA_DI_CARICO BDC ON (C.PartitaIVA = BDC.Cliente AND C.SiglaPaese = BDC.PaeseCliente) WHERE
		BDC.NumeroDoc = numBolla;
	
	RETURN imponibile - (imponibile * (scontoCliente/100));
END |

DELIMITER ;


-- 6) Funzione che, fornito l'identificatore primario (PartitaIVA, SiglaPaese) di un'AZIENDA, restituisce uno dei telefoni (Prefisso+Numero) appartenenti 
-- all'azienda data in input.
DELIMITER |

CREATE FUNCTION NumeroTelefono(parIVA VARCHAR(15), sigPaese CHAR(3)) RETURNS CHAR(15)
BEGIN
	DECLARE pref CHAR(4);
	DECLARE num CHAR(10);
	
	SELECT Prefisso, Numero
	INTO pref, num
	FROM TELEFONO
	WHERE (PartitaIVA = parIVA AND NazionePossessore = sigPaese)
	LIMIT 1;
	
	RETURN CONCAT(pref, ' ', num);
END |

DELIMITER ;


-- 7) Funzione che, fornito l'identificatore primario (PartitaIVA, SiglaPaese) di un'AZIENDA RICEVENTE, restituisce il suo indirizzo di consegna delle merci.
-- Nota: L'indirizzo di consegna di un'AZIENDA RICEVENTE e': l'indirizzo del DEPOSITO, se l'azienda ne possiede uno; oppure l'indirizzo dell'AZIENDA stessa 
-- nel caso tale azienda non possieda alcun deposito (perche' quest'ultimo coincide con la sede aziendale).
DELIMITER |

CREATE FUNCTION IndirizzoConsegnaRicevente(PartitaIVA_Ricevente VARCHAR(15), SiglaPaese_Ricevente CHAR(3)) RETURNS VARCHAR(120)
BEGIN
	DECLARE via VARCHAR(50);
	DECLARE civico SMALLINT(5);
	DECLARE cap CHAR(5);
	DECLARE citta VARCHAR(40);
	DECLARE paese CHAR(3);
	
	DECLARE numRighe INT;
	DECLARE newCivico CHAR(5);
	
	SELECT D.Via, D.Civico, D.CAP, D.Citta, D.Paese, COUNT(*)
	INTO via, civico, cap, citta, paese, numRighe
	FROM DEPOSITO D
	WHERE D.Ricevente=PartitaIVA_Ricevente AND D.NazioneProprietario=SiglaPaese_Ricevente;
	
	IF (numRighe = 0) THEN
		SELECT A.Via, A.Civico, A.CAP, A.Citta, A.SiglaPaese
		INTO via, civico, cap, citta, paese
		FROM AZIENDA A
		WHERE A.PartitaIVA=PartitaIVA_Ricevente AND A.SiglaPaese=SiglaPaese_Ricevente;
	END IF;
	
	SET newCivico = CAST(civico AS CHAR(5));
	
	RETURN CONCAT(via, ' - ', newCivico, ' - ', cap, ' - ', citta, ' - ', paese);
END |

DELIMITER ;




-- TRIGGER:

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
		-- SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La cancellazione della lista e'' fallita: Violazione del vincolo con bolla di carico.';
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
		-- SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La cancellazione della responsabilita e'' fallita: Violazione del vincolo con bolla di carico.';
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
		-- SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Il valore di Sconto appena inserito supera il 50%.';
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
		-- SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Il valore di Sconto appena aggiornato supera il 50%.';
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
		-- SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La durata del contratto risulta inferiore a 3 mesi, oppure il contratto risulta gia'' scaduto.';
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
		-- SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Inserimento fallito! Si ricorda che: DataEmissione <= DataInvio <= DataConsegna.';
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




-- POPULATION:

/*
SET FOREIGN_KEY_CHECKS=0;

TRUNCATE TABLE NAZIONE;
TRUNCATE TABLE CONTAINER;
TRUNCATE TABLE MEZZO_DI_TRASPORTO;
TRUNCATE TABLE PACCO;
TRUNCATE TABLE SPEDIZIONE;
TRUNCATE TABLE AZIENDA;
TRUNCATE TABLE CLIENTE;
TRUNCATE TABLE RICEVENTE;
TRUNCATE TABLE DEPOSITO;
TRUNCATE TABLE TELEFONO;
TRUNCATE TABLE OPERAIO;
TRUNCATE TABLE PARTNER;
TRUNCATE TABLE BOLLA_DI_CARICO;
TRUNCATE TABLE LISTA;
TRUNCATE TABLE RESPONSABILITA;
TRUNCATE TABLE FORNITURA;
TRUNCATE TABLE DELEGA;

SET FOREIGN_KEY_CHECKS=1;
*/


INSERT INTO NAZIONE (Sigla, Nome) VALUES ('ITA', 'Italia');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('FRA', 'Francia');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('AUT', 'Austria');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('CHE', 'Svizzera');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('NLD', 'Paesi Bassi');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('SVN', 'Slovenia');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('USA', 'Stati Uniti D''America');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('SGP', 'Singapore');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('DEU', 'Germania');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('CHL', 'Cile');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('FIN', 'Finlandia');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('IDN', 'Indonesia');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('AUS', 'Australia');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('ESP', 'Spagna');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('DNK', 'Danimarca');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('BEL', 'Belgio');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('GBR', 'Gran Bretagna');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('LKA', 'Sri Lanka');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('THA', 'Thailandia');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('VNM', 'Vietnam');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('CUB', 'Cuba');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('QAT', 'Qatar');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('CHN', 'Cina');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('LUX', 'Lussemburgo');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('MDG', 'Madagascar');
INSERT INTO NAZIONE (Sigla, Nome) VALUES ('TUR', 'Turchia');


INSERT INTO CONTAINER (Dimensione, Materiale, VolumeInterno, Tara, PesoMassimo, Costo, Colore) VALUES ('Piccolo', 'Acciaio', 33.20, 980, 10230, 20.80, 'Marrone');
INSERT INTO CONTAINER (Dimensione, Materiale, VolumeInterno, Tara, PesoMassimo, Costo, Colore) VALUES ('Medio', 'Alluminio', 67.70, 1830, 21200, 31.24, 'Grigio');
INSERT INTO CONTAINER (Dimensione, Materiale, VolumeInterno, Tara, PesoMassimo, Costo, Colore) VALUES ('Grande', 'Acciaio', 83.00, 2250, 28230, 38.30, NULL);


INSERT INTO MEZZO_DI_TRASPORTO (Categoria, Capacita, CostoBase, Container) VALUES ('Camion', 1, 41.28, 'Piccolo');
INSERT INTO MEZZO_DI_TRASPORTO (Categoria, Capacita, CostoBase, Container) VALUES ('Aereo', 3, 60.72, 'Medio');
INSERT INTO MEZZO_DI_TRASPORTO (Categoria, Capacita, CostoBase, Container) VALUES ('Nave', 180, 52.00, 'Grande');


INSERT INTO PACCO (Tipo, Materiale, Larghezza, Lunghezza, Altezza, Peso) VALUES ('Cassa', 'Legno', 1.17, 1.96, 1.19, 590);
INSERT INTO PACCO (Tipo, Materiale, Larghezza, Lunghezza, Altezza, Peso) VALUES ('Barile', 'Acciaio', 0.85, 0.85, 1.80, 100);
INSERT INTO PACCO (Tipo, Materiale, Larghezza, Lunghezza, Altezza, Peso) VALUES ('Scatolone', 'Cartone', 1.17, 0.98, 0.59, 54);
INSERT INTO PACCO (Tipo, Materiale, Larghezza, Lunghezza, Altezza, Peso) VALUES ('Sacco', 'Nylon', 0.98, 1.17, 0.23, 23);


INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Parigi', 4.3, 448, 'Camion');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Milano', 10.4, 1066, 'Camion');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Rome', 15.2, 1639, 'Camion');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Vienna', 10.3, 1161, 'Camion');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Madrid', 16.2, 1730, 'Camion');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Silkeborg', 7.4, 825, 'Camion');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Amsterdam', 1.3, 80, 'Camion');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Frankfurt', 4.2, 455, 'Camion');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Prague', 8.2, 930, 'Camion');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Miami', 280, 6613, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Antwerp', 240.2, 240, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Hamburg', 20, 495, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Amsterdam', 5.4, 109, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Bilbao', 51.2, 1241, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Shanghai', 703.2, 16938, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Bankok', 608, 14676, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Hannover', 4.1, 423, 'Camion');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Manila', 641.4, 15496, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Colombo', 450.2, 10871, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Boston', 214.3, 5174, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Pittsburg', 542, 13081, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('San Francisco', 539.3, 13013, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Amsterdam', 0.4, 71, 'Aereo');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Da Nang', 600.2, 14988, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Beaumont', 334, 8061, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Singapore', 552.1, 13338, 'Nave');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Madrid', 4.1, 1425, 'Aereo');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Lisbona', 20.3, 2174, 'Camion');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Bern', 2.4, 594, 'Aereo');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Frankfurt', 3.5, 357, 'Aereo');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Prague', 5.2, 726, 'Aereo');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Shanghai', 16.4, 8935, 'Aereo');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Luxembourg', 2.3, 262, 'Aereo');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('London', 1.1, 321, 'Aereo');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Colombo', 13.4, 8408, 'Aereo');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('New York', 11.1, 5859, 'Aereo');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Doha', 8.1, 4926, 'Aereo');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Melbourne', 25.3, 16500, 'Aereo');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Parigi', 3.3, 377, 'Aereo');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Singapore', 17.4, 10536, 'Aereo');
INSERT INTO SPEDIZIONE (LuogoDestinazione, Tempo, Distanza, Mezzo) VALUES ('Huasco', 456.2, 10869, 'Nave');


INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00892560491', 'ZIM LTD.', 'Rue Pierre Brossolotte', 7, '76600', 'Le Havre', 'enquiries@zimpost.co.fr', 'FRA');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00895432614', 'FRANCE CARGO INTERNATIONAL COMPANY', 'Avenue Marc Sanginer', 17, '92390', 'Villeneuve La Garenne', 'fci@fci-cie.com', 'FRA');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00963400156', 'EWALS CARGO CARE B.V.', 'Ariensstraat', 63, '5931', 'Tegelen', 'info@ewals.com', 'NLD');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00968203868', 'CARGO LOGISTICS OLANDA', 'Vijzelweg', 1501, '5145', 'Waalwijk', 'info@cargologistics.nl', 'NLD');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00965640892', 'VOS LOGISTICS', 'Vorstengrafdonk', 39, '5342', 'Oss', 'corporate@voslogistics.com', 'NLD');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('20455689001', 'RANK VISSE', 'Rinjzelweg', 4, '5042', 'Waalwijk', 'corporation@rankvisse.com', 'NLD');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00962537491', 'KERRY ADCO LOGISTICS BV', 'Albert Plesmanweg', 63, '3088', 'Rotterdam', 'contact@kerryadco.com', 'NLD');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00965541009', 'AMS LOGISTICS B.V.', 'Shannonweg', 21, '1118', 'Schiphol', 'info@amslogistics.net', 'NLD');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00312150588', 'ABA-INVEST', 'Opernring', 3, '1010', 'Wein', 'office@aba.gv.at', 'AUT');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00317423959', 'LOGWIN SOLUTIONS AUSTRIA GMBH', 'Warneckestrasse', 9, '1110', 'Vienna', 'austria@logwin-logistics.com', 'AUT');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00425432614', 'ALTIUS', 'Hermosilla', 30, '28001', 'Madrid', 'info@grupoaltius.com', 'ESP');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00484528110', 'TRASCOMA LOGISTICS', 'Carrer de Atlantic', 112, '08040', 'Barcelona', 'jsala@transcomalogistics.com', 'ESP');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('02729580841', 'CS4 LOGISTICS', 'Gutenbergring', 67, '22848', 'Norderstedt Hamburg', 'torsten.ehrhorn@cs4.de', 'DEU');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('02728100373', 'LIDL STIFTUNG & CO.KG', 'Stiftsbergstrabe', 1, '74167', 'Neckarsulm', 'kontakt@lidl.com', 'DEU');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('02799728174', 'KOPF & LUBBEN GMBH', 'Cargo City Sud', 537, '60549', 'Frankfurt', 'info@kopf-luebben.com', 'DEU');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('02135020093', 'CONCEPTUM LOGISTICS', 'Alsterarkaden ', 27, '20354', 'Hamburg', 'shipping@conceptum-logistics.de', 'DEU');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('02711651894', 'NNR+DACHSER GMBH', 'Cargo Modul F', 5, '85356', 'Munchen', 'nnr.muenchen@dachser.com', 'DEU');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('27001200736', 'FCA US LLC', 'Auburn Hills', 1000, '48326', 'Michigan', 'investor.relations@fcagroup.com', 'USA');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('27056525984', 'EURO-AMERICAN', 'Mcclellan Highway', 440, '02128', 'Massachusetts', 'info@eaafinc.net', 'USA');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('27561083928', 'NORTH AMERICAN LOGISTICS SERVICES INC.', 'Simpson Road', 49, '72', 'Ontario', 'operations@nalsi.com', 'USA');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('27093510317', 'AMERICAN LOGISTICS GROUP', 'S Service Road', 68, '11747', 'New York', 'info@alg.us.com', 'USA');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00427381849', 'ANDES LOGISTICS CHILE', 'Av. Alonso de Cordova', 201, '5900', 'Santiago', 'sales@andeslogistics.cl', 'CHL');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('08657103288', 'TRANSPORTATION AMERICA', 'Alvares Street', 406, '78047', 'Punta Arenas', 'transport@transportationamerica.cl', 'CHL');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00429580841', 'ALOG CILE A.G.', 'Puerto Madero', 18, '9710', 'Santiago', 'alog@alog.cl', 'CHL');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('88595541009', 'COSCO GROUP', 'Fuxingmennei Street', 158, '10031', 'Beijing', 'internet@cosco.com', 'CHN');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('88787245262', 'CHINA WHEEL SHIPPING', 'Wing Lok Street', 7, '11239', 'Sheung Wan', 'info@cws.com.hk', 'CHN');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('88742653271', 'YUSEN LOGISTICS', 'Xizang Road', 20, '20001', 'Shanghai', 'info@yusen.com', 'CHN');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00637253841', 'SIEMENS CO.', 'Woodyard Lane', 100, '81', 'Nottingham', 'sales.gbi.industry@siemens.com', 'GBR');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00632038273', 'HARRODS', 'Brompton Road', 87, '71', 'London', 'help@harrods.com', 'GBR');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00637916459', 'BISHOPSGATE', 'Acton Lane', 141, '107', 'London', 'bishopslogistics@uk.com', 'GBR');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('03458239560', 'CRIMSON CANC', 'Jeremy Route', 54, '113', 'London', 'crimsoncancel@uk.com', 'GBR');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('35891759722', 'SAMSUNG ELECTRONICS VIETNAM CO.', 'Yen Phong ', 1, '541', 'Hanoi', 'sev@samsung.com', 'VNM');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('03957900487', 'SAMMONTANA S.P.A.', 'Via Tosco Romagnola', 56, '50053', 'Empoli', 'dirmarketing@sammontana.it', 'ITA');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00876320409', 'S.G.M.DISTRIBUZIONE S.R.L.', 'Via V. Schiaparelli', 31, '47122', 'Forli', 'info@sgmdistribuzione.it', 'ITA');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('04917150155', 'TOMET S.R.L.', 'Via Monte Ortigara', 20, '36078', 'Valdagno', 'info@tomet.com', 'ITA');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00795286388', 'FRODE LAURSEN', 'Vittenvej', 90, '8382', 'Hinnerup', 'info@frode-laursen.com', 'DNK');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00253475907', 'BARCO N.V.', 'Benelux park ', 21, '8510', 'Kortrijk', 'info@barco.be', 'BEL');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('53781947300', 'HELLMANN', 'C Ring Road', 75, '22770', 'Doha', 'sales@qatarlogistics.com', 'QAT');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('12595541009', 'B&C SWISS', 'Via Laveggio', 3, '6855', 'Svizzera', 'info@bec-swiss.ch', 'CHE');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('07453129873', 'NVIDIA BVI Holdings Ltd.', 'Gongdao 5th Road', 2, '300', 'Hsinchu', 'nvj-inquiry@nvidia.com', 'THA');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('67437910472', 'SHINE FORTH CO.', 'Royal City Avenue', 2, '10320', 'Bangkok', 'vilai@fruitcellar.net', 'THA');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('60297583425', 'BEE CHENG HIANG', 'Serangoon Road', 135, '300', 'Novena', 'bch@bch.com.sg', 'SGP');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('09561272314', 'MORRISON EXPRESS', 'Cargo Center Luxair', 435, '1360', 'Luxembourg', 'info@morrison.com', 'LUX');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('11972864894', 'ESTORE', 'Dandenong South', 4, '3175', 'Melbourne', 'info@estorelogistics.com.au', 'AUS');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00958203841', 'INCITEC PIVOT LTD.', 'Freshwater Place', 28, '3006', 'Melbourne', 'flugge@incitecpivot.au', 'AUS');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('00475895821', 'DE BORTOLI WINES', 'De Bortoli Road', 21, '2680', 'Bilbul', 'info@debortoli.com.au', 'AUS');
INSERT INTO AZIENDA (PartitaIVA, Nome, Via, Civico, CAP, Citta, E_Mail, SiglaPaese) VALUES ('40782120192', 'CEYLON ELECTRCITY BOARD', 'Sir Chittampalam', 2, '148', 'Colombo', 'info@ceyelectric.lk', 'LKA');


INSERT INTO CLIENTE (PartitaIVA, SiglaPaese) VALUES ('00892560491', 'FRA');
INSERT INTO CLIENTE (PartitaIVA, SiglaPaese) VALUES ('00963400156', 'NLD');
INSERT INTO CLIENTE (PartitaIVA, SiglaPaese) VALUES ('00968203868', 'NLD');
INSERT INTO CLIENTE (Convenzionato, Sconto, PartitaIVA, SiglaPaese) VALUES (True, 1, '00965640892', 'NLD');
INSERT INTO CLIENTE (Convenzionato, Sconto, PartitaIVA, SiglaPaese) VALUES (True, 2, '02729580841', 'DEU');
INSERT INTO CLIENTE (Convenzionato, Sconto, PartitaIVA, SiglaPaese) VALUES (True, 2, '02799728174', 'DEU');
INSERT INTO CLIENTE (PartitaIVA, SiglaPaese) VALUES ('02135020093', 'DEU');
INSERT INTO CLIENTE (Convenzionato, Sconto, PartitaIVA, SiglaPaese) VALUES (True, 1, '27001200736', 'USA');
INSERT INTO CLIENTE (PartitaIVA, SiglaPaese) VALUES ('27056525984', 'USA');
INSERT INTO CLIENTE (PartitaIVA, SiglaPaese) VALUES ('00427381849', 'CHL');
INSERT INTO CLIENTE (Convenzionato, Sconto, PartitaIVA, SiglaPaese) VALUES (True, 2, '00429580841', 'CHL');
INSERT INTO CLIENTE (Convenzionato, Sconto, PartitaIVA, SiglaPaese) VALUES (True, 5, '00958203841', 'AUS');
INSERT INTO CLIENTE (Convenzionato, Sconto, PartitaIVA, SiglaPaese) VALUES (True, 3, '00475895821', 'AUS');
INSERT INTO CLIENTE (Convenzionato, Sconto, PartitaIVA, SiglaPaese) VALUES (True, 3, '88595541009', 'CHN');
INSERT INTO CLIENTE (Convenzionato, Sconto, PartitaIVA, SiglaPaese) VALUES (True, 2, '88787245262', 'CHN');
INSERT INTO CLIENTE (PartitaIVA, SiglaPaese) VALUES ('88742653271', 'CHN');
INSERT INTO CLIENTE (PartitaIVA, SiglaPaese) VALUES ('08657103288', 'CHL');
INSERT INTO CLIENTE (Convenzionato, Sconto, PartitaIVA, SiglaPaese) VALUES (True, 5, '00637253841', 'GBR');
INSERT INTO CLIENTE (Convenzionato, Sconto, PartitaIVA, SiglaPaese) VALUES (True, 1, '00632038273', 'GBR');
INSERT INTO CLIENTE (PartitaIVA, SiglaPaese) VALUES ('03957900487', 'ITA');
INSERT INTO CLIENTE (Convenzionato, Sconto, PartitaIVA, SiglaPaese) VALUES (True, 2, '00876320409', 'ITA');
INSERT INTO CLIENTE (Convenzionato, Sconto, PartitaIVA, SiglaPaese) VALUES (True, 3, '04917150155', 'ITA');
INSERT INTO CLIENTE (PartitaIVA, SiglaPaese) VALUES ('00795286388', 'DNK');
INSERT INTO CLIENTE (PartitaIVA, SiglaPaese) VALUES ('00253475907', 'BEL');


INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('00892560491', 'FRA');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('00895432614', 'FRA');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('00963400156', 'NLD');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('00968203868', 'NLD');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('00962537491', 'NLD');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('00965541009', 'NLD');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('00312150588', 'AUT');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('00317423959', 'AUT');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('00425432614', 'ESP');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('00484528110', 'ESP');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('02729580841', 'DEU');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('02728100373', 'DEU');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('02799728174', 'DEU');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('02711651894', 'DEU');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('27001200736', 'USA');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('03458239560', 'GBR');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('27056525984', 'USA');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('27561083928', 'USA');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('27093510317', 'USA');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('88787245262', 'CHN');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('88595541009', 'CHN');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('00637253841', 'GBR');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('00637916459', 'GBR');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('35891759722', 'VNM');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('03957900487', 'ITA');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('00876320409', 'ITA');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('00253475907', 'BEL');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('53781947300', 'QAT');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('12595541009', 'CHE');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('07453129873', 'THA');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('67437910472', 'THA');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('60297583425', 'SGP');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('20455689001', 'NLD');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('09561272314', 'LUX');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('11972864894', 'AUS');
INSERT INTO RICEVENTE (PartitaIVA, SiglaPaese) VALUES ('40782120192', 'LKA');


INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Vanderlandelaan', 2, '5466', 'Veghel', 'NLD', '00892560491', 'FRA', 2);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Avenue Marx Dormoy', 21, '13230', 'Port Saint Louis Du Rhone', 'FRA', '00895432614', 'FRA', NULL);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('De Poppe', 16, '7587', 'De Lutte', 'NLD', '00963400156', 'NLD', 2);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Bellsingel', 11, '1119', 'Schiphol-Rijk', 'NLD', '00968203868', 'NLD', NULL);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Fokkerweg ', 2, '1438', 'Oude Meer', 'NLD', '00965541009', 'NLD', 2);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Opernring', 31, '1010', 'Wein', 'AUT', '00312150588', 'AUT', NULL);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Fokrau', 79, '1440', 'Oude Meer', 'NLD', '00317423959', 'AUT', 1);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Albert Plesmanweg', 41, '3088', 'Rotterdam', 'NLD', '00425432614', 'ESP', NULL);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Wilhelm-Lodige-Str', 6, '34414', 'Barcelona', 'ESP', '00484528110', 'ESP', NULL);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Hans Strasse', 77, '74167', 'Neckarsulm', 'DEU', '02728100373', 'DEU', 4);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Bolwerklaan', 21, '1210', 'Brussels', 'BEL', '02799728174', 'DEU', 3);
-- INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Cargo Modul F', 5, '85356', 'Munchen', 'DEU', '02711651894', 'DEU', NULL);
-- INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Auburn Hills', 1000, '48326', 'Michigan', 'USA', '27001200736', 'USA', 1);
-- INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('South Abilene', 1700, '80012', 'Aurora', 'USA', '27056525984', 'USA', 2);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Simpson Street', 60, '678', 'Ontario', 'USA', '27561083928', 'USA', NULL);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('American Way', 8820, '80112', 'Englewood', 'USA', '27093510317', 'USA', 2);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Fuxingmennei Street', 200, '10031', 'Sheung Wan', 'CHN', '88595541009', 'CHN', NULL);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Connaught Road ', 70, '12940', 'Rotterdam', 'CHN', '88787245262', 'CHN', 2);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Summerlee Street', '100', 'G33', 'Glasgow', 'GBR', '00637253841', 'GBR', 3);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Via Arti e Mestieri', 11, '50056', 'Fiorentino', 'ITA', '03957900487', 'ITA', 3);
-- INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Via V. Schiaparelli', 31, '47122', 'Forli', 'ITA', '00876320409', 'ITA', 2);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Acton Lane', 141, '107', 'Kapellen', 'BEL', '00253475907', 'BEL', 1);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('C Lang Street', 30, '45709', 'Doha', 'QAT', '53781947300', 'QAT', NULL);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Lieven Gevaertstraat', 11, '22770', 'Kapellen', 'BEL', '12595541009', 'CHE', 1);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Gongdao 6th Road', 2, '307', 'Hsinchu', 'THA', '07453129873', 'THA', 4);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Orchard Road', 400, '23875', 'Orchard Towers', 'SGP', '60297583425', 'SGP', 1);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Royal City Avenue', 34, '7587', 'De Lutte', 'NLD', '09561272314', 'LUX', 1);
-- INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Macadam St', 12, '4073', 'Seventeen Mile', 'AUS', '11972864894', 'AUS', 1);
INSERT INTO DEPOSITO (Via, Civico, CAP, Citta, Paese, Ricevente, NazioneProprietario, NumeroPiani) VALUES ('Tran Dang Ninh', 17, '371', 'Colombo', 'LKA', '40782120192', 'LKA', 1);


INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0033', '232749516', '00892560491', 'FRA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0033', '140850776', '00895432614', 'FRA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0033', '140850774', '00895432614', 'FRA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0031', '168350300', '00963400156', 'NLD');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0031', '416671843', '00968203868', 'NLD');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0031', '412699599', '00965640892', 'NLD');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0031', '205046800', '00962537491', 'NLD');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0031', '203164915', '00965541009', 'NLD');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0031', '203164910', '00965541009', 'NLD');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0043', '001588580', '00312150588', 'AUT');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0043', '001760440', '00317423959', 'AUT');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0043', '001760452', '00317423959', 'AUT');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0043', '001760447', '00317423959', 'AUT');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0034', '914311363', '00425432614', 'ESP');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0034', '917480690', '00484528110', 'ESP');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0034', '917480686', '00484528110', 'ESP');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0049', '729580841', '02729580841', 'DEU');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0049', '729580856', '02729580841', 'DEU');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0049', '713294200', '02728100373', 'DEU');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0049', '421389910', '02799728174', 'DEU');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0049', '403037210', '02135020093', 'DEU');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0049', '211471151', '02711651894', 'DEU');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0049', '211471170', '02711651894', 'DEU');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0001', '800334920', '27001200736', 'USA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0001', '028690841', '27056525984', 'USA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0001', '905951161', '27561083928', 'USA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0001', '905951162', '27561083928', 'USA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0031', '189276093', '27093510317', 'USA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0031', '189276098', '27093510317', 'USA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0056', '017198484', '00427381849', 'CHL');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0056', '025448581', '00429580841', 'CHL');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0056', '025448591', '00429580841', 'CHL');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0086', '216596112', '88595541009', 'CHN');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0086', '198255662', '88787245262', 'CHN');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0086', '199206379', '88742653271', 'CHN');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0086', '199206377', '88742653271', 'CHN');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0086', '199206378', '88742653271', 'CHN');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0044', '887244108', '00637253841', 'GBR');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0044', '412277910', '00632038273', 'GBR');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0044', '007282816', '00637916459', 'GBR');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0084', '677756201', '35891759722', 'VNM');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0084', '677756199', '35891759722', 'VNM');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0039', '432997314', '03957900487', 'ITA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0039', '543776411', '00876320409', 'ITA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0039', '543776405', '00876320409', 'ITA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0039', '543776417', '00876320409', 'ITA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0039', '445941307', '04917150155', 'ITA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0039', '445941298', '04917150155', 'ITA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0039', '445941310', '04917150155', 'ITA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0045', '992881882', '00795286388', 'DNK');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0032', '411992781', '00253475907', 'BEL');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0032', '411992771', '00253475907', 'BEL');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0032', '411992766', '00253475907', 'BEL');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0974', '990778215', '53781947300', 'QAT');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0041', '463388199', '12595541009', 'CHE');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0041', '463388190', '12595541009', 'CHE');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0066', '566511449', '07453129873', 'THA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0066', '566511450', '07453129873', 'THA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0066', '882671004', '67437910472', 'THA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0065', '778291642', '60297583425', 'SGP');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0065', '778291548', '60297583425', 'SGP');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0352', '066297441', '09561272314', 'LUX');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0043', '887296432', '11972864894', 'AUS');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0043', '887296443', '11972864894', 'AUS');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0043', '887296442', '11972864894', 'AUS');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0043', '887296447', '11972864894', 'AUS');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0043', '887296449', '11972864894', 'AUS');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0043', '889647728', '00958203841', 'AUS');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0043', '884611425', '00475895821', 'AUS');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0094', '002517869', '40782120192', 'LKA');
INSERT INTO TELEFONO (Prefisso, Numero, PartitaIVA, NazionePossessore) VALUES ('0094', '002517874', '40782120192', 'LKA');


INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('RSSMRA13S08H501H', 'Rossi', 'Mario', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('GRZGLI68A41L551A', 'Grazon', 'Giulia', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('GRZGAI79A45L736E', 'Graziati', 'Gaia', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('TRDSMN74A01L736Z', 'Tardiani', 'Simone', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('MCNTMM83E12E897E', 'Mancini', 'Tommaso', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('BRWLCS78D03K657X', 'Brown', 'Lucas', 'USA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('MLRPTR84L30C933X', 'Migliorini', 'Pietro', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('PNIFPP67D17G535K', 'Pini', 'Filippo', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('TLLRHL79R12G224G', 'Tellaroli', 'Rachele', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('MZRMLY77D65G224H', 'Mazaretto', 'Emily', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('BSTLSS63L18G702N', 'Besutti', 'Alessio', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('ZNGMNL63C04G273V', 'Zang', 'Manuel', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('BRTLCU71C01G273L', 'Bertolani', 'Luca', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('MLNDRD64B01F205B', 'Molinari', 'Edoardo', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('DNGMME80L56L840K', 'De Angeli', 'Emma', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('RMRSRA70B41L840G', 'Raumer', 'Sara', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('RNIZNE76B41L840V', 'Riani', 'Zeno', 'ITA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('PTRSMN86E12L219B', 'Patrick', 'Simon', 'USA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('PTRPLL91H10F839T', 'Patrick', 'Phillips', 'USA');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('DLFGDA60P12L407B', 'Adolfo', 'Agueda', 'ESP');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('DLMLVR83L18E098X', 'Adelmo', 'Alvaro', 'ESP');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('CLSNRS72H13A271T', 'Celso', 'Andres', 'ESP');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('ZOEMXA90M23A794N', 'Zoe', 'Max', 'NLD');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('FMKSVN69P06A944O', 'Femke', 'Sven', 'NLD');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('SNNMLI88H44D643Z', 'Sanne', 'Mila', 'NLD');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('SMTJHN84F11R320Y', 'Smith', 'John', 'AUS');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('CHRBJM88H04F839Z', 'Charlotte', 'Benjamin', 'NLD');
INSERT INTO OPERAIO (CF, Cognome, Nome, NazioneNascita) VALUES ('PNTNGL12P49H501B', 'Pinet', 'Angela', 'FRA');


INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('Hamburg-Sud', '2013-04-17', '2017-04-16', NULL);
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('CMA-CGM', '2005-11-01', '2018-10-31', 'Together Stronger');
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('Evergreen Marine CORP.', '2009-05-14', '2019-05-13', 'Guarding Our Green Earth');
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('Maersk Line', '2013-01-14', '2017-01-13', NULL);
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('Rickmers-Linie', '2013-04-10', '2017-04-09', NULL);
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('Polynesian Shipping Company', '2015-02-18', '2018-02-17', NULL);
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('Grimaldi Lines', '2005-03-16', '2018-03-15', NULL);
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('Reederei NSB', '2009-05-14', '2019-05-13', NULL);
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('Etihad Cargo', '2014-06-10', '2019-06-09', 'Fastest Cargo Airline.');
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('Luftansa Cargo', '2013-02-04', '2018-02-03', 'Networking The World');
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('Emirates SkyCargo', '2015-04-05', '2020-04-04', 'Hello Tomorrow');
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('CARGOJET', '2014-05-10', '2017-05-09', 'The Most Awarded Air Cargo in Canada');
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('Avianca Cargo', '2014-08-10', '2017-08-09', NULL);
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('Singapore Cargo', '2014-08-10', '2017-08-09', NULL);
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('ABC Services', '2014-06-06', '2017-06-05', NULL);
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('ANA Cargo', '2015-03-29', '2020-03-28', NULL);
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('Cathay Pacific Cargo', '2012-08-18', '2017-08-17', NULL);
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('UPS Cargo', '2012-04-24', '2018-04-23', NULL);
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('DHL Cargo', '2016-01-24', '2021-01-23', NULL);
INSERT INTO PARTNER (Nome, InizioContratto, FineContratto, Slogan) VALUES ('TNT Services', '2015-09-05', '2020-09-04', 'The People Network');


INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('000094', 'Raf Alex', 				'2010-08-08', '2010-08-08', '2010-08-06', 'MasterCard', 	NULL, '00965541009', 'NLD', '00632038273', 'GBR', 'Amsterdam', 'Camion');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('000180', 'Dion Imran', 			'2010-08-10', '2010-08-06', '2010-08-06', 'MasterCard', 	NULL, '00963400156', 'NLD', '00632038273', 'GBR', 'Amsterdam', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('000974', 'Mark Boyce', 			'2011-11-14', '2011-11-14', '2011-11-14', 'Assegno', 		NULL, '00637253841', 'GBR', '00965640892', 'NLD', 'London', 'Aereo');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('001025', 'Wesley Damian', 		'2011-10-24', '2011-10-23', '2011-10-20', 'Assegno', 		NULL, '00637916459', 'GBR', '00965640892', 'NLD', 'London', 'Aereo');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('002074', 'Yannick Manuel', 		'2011-05-13', '2011-05-11', '2011-05-11', 'MasterCard', 	NULL, '02728100373', 'DEU', '00795286388', 'DNK', 'Frankfurt', 'Camion');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('002103', 'Garrey Hewett', 		'2012-03-25', '2012-03-15', '2012-03-14', 'Assegno', 		NULL, '00253475907', 'BEL', '00637253841', 'GBR', 'Antwerp', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('002284', 'Mitchell Kris', 		'2012-03-25', '2012-03-24', '2012-03-23', 'Contanti', 	NULL, '11972864894', 'AUS', '00963400156', 'NLD', 'Melbourne', 'Aereo');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('003019', 'Arda Viggo', 			'2013-08-27', '2013-08-08', '2013-08-06', 'MasterCard', 	NULL, '00962537491', 'NLD', '00427381849', 'CHL', 'Amsterdam', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('003180', 'Yusuf Muhammed', 		'2013-08-27', '2013-08-08', '2013-08-06', 'MasterCard', 	NULL, '35891759722', 'VNM', '00253475907', 'BEL', 'Huasco', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('003200', 'Jacinto Guillermo', 	'2013-08-31', '2013-08-13', '2013-08-13', 'MasterCard', 	NULL, '67437910472', 'THA', '02135020093', 'DEU', 'Bankok', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('003291', 'Basilio Diego', 		'2013-06-25', '2013-06-24', '2013-06-23', 'Assegno', 		'Easily contaminating things are inside.', '00895432614', 'FRA', '88595541009', 'CHN', 'Parigi', 'Aereo');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('003434', 'Fidel Constantino', 	'2013-03-23', '2013-03-23', '2013-03-23', 'MasterCard', 	NULL, '53781947300', 'QAT', '00892560491', 'FRA', 'Colombo', 'Aereo');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('003912', 'Cesaro Enzo', 			'2013-08-27', '2013-08-08', '2013-08-06', 'MasterCard', 	NULL, '00968203868', 'NLD', '00427381849', 'CHL', 'Amsterdam', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('003981', 'Robert Bruce', 			'2013-08-13', '2013-08-12', '2013-08-11', 'PayPal', 		NULL, '00484528110', 'ESP', '02729580841', 'DEU', 'Madrid', 'Camion');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('004214', 'Zacarias Thiago', 		'2014-04-28', '2014-04-27', '2014-04-26', 'MasterCard', 	NULL, '02711651894', 'DEU', '27056525984', 'USA', 'Hamburg', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('004281', 'Adalwen Burnell', 		'2014-10-05', '2014-09-11', '2014-09-10', 'Contanti', 	NULL, '35891759722', 'VNM', '00968203868', 'NLD', 'Da Nang', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('004564', 'Johan Sebastian', 		'2014-08-19', '2014-07-06', '2014-07-03', 'PayPal', 		NULL, '27561083928', 'USA', '88742653271', 'CHN', 'New York', 'Aereo');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('004734', 'Cesaro Enrico', 		'2014-10-12', '2014-09-17', '2014-09-15', 'PayPal', 		NULL, '00484528110', 'ESP', '00968203868', 'NLD', 'Huasco', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('004979', 'Yannick Manuel	', 		'2014-05-19', '2014-05-19', '2014-05-18', 'MasterCard', 	NULL, '02799728174', 'DEU', '27056525984', 'USA', 'Frankfurt', 'Aereo');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('006685', 'Ferde Dieter', 			'2015-06-11', '2015-06-10', '2015-06-10', 'MasterCard', 	NULL, '00425432614', 'ESP', '02729580841', 'DEU', 'Madrid', 'Camion');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('006842', 'Ralph Shane', 			'2015-11-06', '2015-11-05', '2015-11-05', 'PayPal', 		'Do not incline vertically. ', '09561272314', 'LUX', '00965640892', 'NLD', 'Luxembourg', 'Aereo');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('006910', 'Bonavoglia Leonardo', 	'2015-02-25', '2015-02-24', '2015-02-24', 'Assegno', 		'Contain inside fragile objects. Take carefully.', '00317423959', 'AUT', '00876320409', 'ITA', 'Vienna', 'Camion');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008241', 'Mark Visser', 			'2016-06-13', '2016-06-01', '2016-05-28', 'MasterCard', 	NULL, '27001200736', 'USA', '00892560491', 'FRA', 'Miami', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008364', 'Stijn Thomas', 			'2016-05-07', '2016-04-07', '2016-04-05', 'PayPal', 		NULL, '88595541009', 'CHN', '00963400156', 'NLD', 'Shanghai', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008514', 'Mark Jaecar', 			'2016-07-04', '2016-07-03', '2016-07-01', 'MasterCard', 	NULL, '03957900487', 'ITA', '02799728174', 'DEU', 'Milano', 'Camion');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008546', 'Mark Boyce', 			'2016-07-05', '2016-07-03', '2016-07-01', 'PayPal', 		'Contain inside fragile objects.', '00876320409', 'ITA', '88595541009', 'CHN', 'Rome', 'Camion');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008614', 'Yannick	 Stefan', 		'2016-08-05', '2016-07-05', '2016-07-01', 'MasterCard',	NULL, '07453129873', 'THA', '88787245262', 'CHN', 'Bankok', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008625', 'Dave lima', 			'2016-04-06', '2016-04-06', '2016-04-03', 'PayPal', 		'Contain inside fragile objects.', '00876320409', 'ITA', '00475895821', 'AUS', 'Rome', 'Camion');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008644', 'Dave Evert', 			'2016-07-05', '2016-07-02', '2016-07-01', 'MasterCard', 	'Contain inside fragile objects.', '12595541009', 'CHE', '00475895821', 'AUS', 'Bern', 'Aereo');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008651', 'Johan Manuel', 			'2016-05-09', '2016-04-06', '2016-04-03', 'MasterCard', 	'Do not shake.', '27561083928', 'USA', '88787245262', 'CHN', 'New York', 'Aereo');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008714', 'Basilio Valentino',		'2016-04-05', '2016-04-04', '2016-04-03', 'MasterCard', 	NULL, '40782120192', 'LKA', '00892560491', 'FRA', 'Colombo', 'Aereo');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008724', 'Jacinto Guillermo',		'2016-03-17', '2016-02-13', '2016-02-13', 'Contanti', 	NULL, '60297583425', 'SGP', '02135020093', 'DEU', 'Singapore', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008745', 'Bonavoglia Leonardo',	'2016-07-01', '2016-06-13', '2016-05-31', 'Contanti', 	'Contain inside fragile objects.', '02728100373', 'DEU', '00876320409', 'ITA', 'Silkeborg', 'Camion');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008754', 'Bonavoglia Leonardo',	'2016-05-29', '2016-05-28', '2016-05-28', 'Assegno', 		'Contain inside fragile objects.', '00312150588', 'AUT', '00876320409', 'ITA', 'Vienna', 'Camion');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008851', 'Giacomin Riccardo',		'2016-07-03', '2016-06-13', '2016-05-29', 'Contanti', 	'Freeze within suitable temperatures.', '27056525984', 'USA', '03957900487', 'ITA', 'Pittsburg', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008893', 'Giacomin Massimiliano',	'2016-04-01', '2016-02-12', '2016-02-10', 'Assegno',		'Freeze within suitable temperatures.', '27001200736', 'USA', '03957900487', 'ITA', 'Miami', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008944', 'Oliver Floris',			'2016-02-24', '2016-02-11', '2016-02-06', 'PayPal', 		'Contain inside fragile objects.', '27561083928', 'USA', '00795286388', 'DNK', 'Beaumont', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008932', 'Wesley Damian',			'2016-02-11', '2016-02-10', '2016-02-10', 'PayPal', 		'Contain inside fragile objects.', '40782120192', 'LKA', '00795286388', 'DNK', 'Colombo', 'Aereo');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008945', 'Chris Alex',			'2016-02-23', '2016-02-10', '2016-02-10', 'PayPal', 		NULL, '27093510317', 'USA', '04917150155', 'ITA', 'Boston', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('008981', 'Rowan Maxim',			'2016-03-11', '2016-02-08', '2016-02-07', 'Assegno', 		'Contain inside fragile objects.', '27093510317', 'USA', '00958203841', 'AUS', 'San Francisco', 'Nave');
INSERT INTO BOLLA_DI_CARICO (NumeroDoc, Corriere, DataConsegna, DataInvio, DataEmissione, MetodoPagamento, Nota, Ricevente, PaeseRicevente, Cliente, PaeseCliente, Destinazione, Mezzo) VALUES ('009047', 'Yusuf Muhammed',		'2016-02-12', '2016-02-10', '2016-02-08', 'PayPal', 		'Contain inside fragile objects.', '53781947300', 'QAT', '02135020093', 'DEU', 'Doha', 'Aereo');


INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('000094', 'Cassa', 41);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('000094', 'Sacco', 15);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('000180', 'Scatolone', 53);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('000180', 'Barile', 12);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('000974', 'Cassa', 6);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('000974', 'Scatolone', 14);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('000974', 'Sacco', 32);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('001025', 'Scatolone', 13);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('002074', 'Sacco', 5);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('002103', 'Barile', 125);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('002284', 'Scatolone', 6);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('002284', 'Barile', 31);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('003019', 'Cassa', 8);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('003019', 'Scatolone', 46);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('003019', 'Barile', 6);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('003019', 'Sacco', 22);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('003180', 'Barile', 28);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('003200', 'Scatolone', 134);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('003200', 'Sacco', 103);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('003291', 'Sacco', 11);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('003434', 'Sacco', 14);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('003912', 'Cassa', 230);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('003981', 'Cassa', 6);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('004214', 'Scatolone', 74);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('004281', 'Barile', 128);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('004564', 'Scatolone', 38);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('004564', 'Sacco', 38);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('004734', 'Barile', 168);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('004979', 'Cassa', 51);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('006685', 'Cassa', 8);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('006685', 'Barile', 89);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('006842', 'Barile', 56);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('006842', 'Sacco', 16);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('006910', 'Cassa', 17);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008241', 'Cassa', 76);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008241', 'Barile', 133);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008364', 'Scatolone', 115);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008514', 'Cassa', 7);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008546', 'Cassa', 16);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008546', 'Scatolone', 41);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008614', 'Scatolone', 64);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008625', 'Cassa', 5);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008644', 'Sacco', 8);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008651', 'Barile', 128);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008714', 'Cassa', 17);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008714', 'Scatolone', 3);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008724', 'Scatolone', 23);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008745', 'Sacco', 13);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008754', 'Scatolone', 62);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008754', 'Sacco', 109);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008851', 'Scatolone', 36);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008893', 'Cassa', 6);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008944', 'Scatolone', 45);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008932', 'Cassa', 29);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008932', 'Scatolone', 45);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008932', 'Barile', 7);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008945', 'Cassa', 20);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008945', 'Scatolone', 32);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008945', 'Barile', 32);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('008981', 'Scatolone', 28);
INSERT INTO LISTA (BollaDiCarico, Pacco, Elementi) VALUES ('009047', 'Cassa', 5);


INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('000094', 'RSSMRA13S08H501H');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('000094', 'TRDSMN74A01L736Z');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('000094', 'BRTLCU71C01G273L');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('000180', 'GRZGLI68A41L551A');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('000974', 'GRZGAI79A45L736E');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('000974', 'PTRPLL91H10F839T');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('001025', 'TRDSMN74A01L736Z');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('002074', 'MCNTMM83E12E897E');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('002103', 'MLRPTR84L30C933X');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('002284', 'PNIFPP67D17G535K');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('003019', 'FMKSVN69P06A944O');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('003019', 'TLLRHL79R12G224G');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('003019', 'PTRPLL91H10F839T');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('003019', 'MCNTMM83E12E897E');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('003180', 'MZRMLY77D65G224H');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('003200', 'GRZGLI68A41L551A');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('003200', 'RMRSRA70B41L840G');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('003291', 'PNIFPP67D17G535K');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('003434', 'BSTLSS63L18G702N');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('003912', 'ZNGMNL63C04G273V');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('003981', 'BRTLCU71C01G273L');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('004214', 'MLNDRD64B01F205B');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('004214', 'BSTLSS63L18G702N');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('004214', 'FMKSVN69P06A944O');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('004281', 'DNGMME80L56L840K');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('004564', 'RMRSRA70B41L840G');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('004564', 'RNIZNE76B41L840V');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('004564', 'BSTLSS63L18G702N');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('004734', 'RNIZNE76B41L840V');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('004979', 'PTRPLL91H10F839T');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('006685', 'FMKSVN69P06A944O');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('006842', 'ZOEMXA90M23A794N');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('006842', 'RNIZNE76B41L840V');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('006910', 'CLSNRS72H13A271T');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008241', 'DLFGDA60P12L407B');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008364', 'FMKSVN69P06A944O');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008514', 'SNNMLI88H44D643Z');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008546', 'TLLRHL79R12G224G');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008614', 'PNIFPP67D17G535K');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008625', 'MCNTMM83E12E897E');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008625', 'ZOEMXA90M23A794N');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008625', 'PTRPLL91H10F839T');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008644', 'TRDSMN74A01L736Z');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008651', 'GRZGLI68A41L551A');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008714', 'GRZGLI68A41L551A');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008724', 'ZNGMNL63C04G273V');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008724', 'DLFGDA60P12L407B');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008724', 'RSSMRA13S08H501H');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008745', 'PTRPLL91H10F839T');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008754', 'BRTLCU71C01G273L');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008851', 'BSTLSS63L18G702N');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008893', 'RSSMRA13S08H501H');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008944', 'RMRSRA70B41L840G');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008932', 'MLNDRD64B01F205B');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008945', 'DLMLVR83L18E098X');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008945', 'RMRSRA70B41L840G');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008945', 'CHRBJM88H04F839Z');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008945', 'PNTNGL12P49H501B');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008945', 'RSSMRA13S08H501H');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('008981', 'CHRBJM88H04F839Z');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('009047', 'PNTNGL12P49H501B');
INSERT INTO RESPONSABILITA (BollaDiCarico, Operaio) VALUES ('009047', 'TLLRHL79R12G224G');


INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Hamburg-Sud', 'Camion');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Hamburg-Sud', 'Nave');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('CMA-CGM', 'Nave');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Evergreen Marine CORP.', 'Nave');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Maersk Line', 'Nave');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Rickmers-Linie', 'Nave');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Polynesian Shipping Company', 'Nave');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Grimaldi Lines', 'Aereo');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Grimaldi Lines', 'Nave');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Luftansa Cargo', 'Aereo');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Luftansa Cargo', 'Nave');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Etihad Cargo', 'Aereo');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Etihad Cargo', 'Nave');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Reederei NSB', 'Nave');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Emirates SkyCargo', 'Aereo');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('CARGOJET', 'Aereo');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Avianca Cargo', 'Aereo');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Avianca Cargo', 'Camion');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Avianca Cargo', 'Nave');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('ABC Services', 'Camion');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Singapore Cargo', 'Aereo');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('ANA Cargo', 'Aereo');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('Cathay Pacific Cargo', 'Aereo');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('UPS Cargo', 'Aereo');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('UPS Cargo', 'Camion');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('DHL Cargo', 'Aereo');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('DHL Cargo', 'Camion');
INSERT INTO FORNITURA (Partner, Mezzo) VALUES ('TNT Services', 'Camion');


INSERT INTO DELEGA (Delegato, SiglaDelegato, Delegante, SiglaDelegante) VALUES ('00965640892', 'NLD', '02799728174', 'DEU');
INSERT INTO DELEGA (Delegato, SiglaDelegato, Delegante, SiglaDelegante) VALUES ('02135020093', 'DEU', '00637253841', 'GBR');
INSERT INTO DELEGA (Delegato, SiglaDelegato, Delegante, SiglaDelegante) VALUES ('00958203841', 'AUS', '88742653271', 'CHN');
INSERT INTO DELEGA (Delegato, SiglaDelegato, Delegante, SiglaDelegante) VALUES ('00958203841', 'AUS', '27001200736', 'USA');
INSERT INTO DELEGA (Delegato, SiglaDelegato, Delegante, SiglaDelegante) VALUES ('00958203841', 'AUS', '02799728174', 'DEU');
INSERT INTO DELEGA (Delegato, SiglaDelegato, Delegante, SiglaDelegante) VALUES ('00632038273', 'GBR', '00637253841', 'GBR');
INSERT INTO DELEGA (Delegato, SiglaDelegato, Delegante, SiglaDelegante) VALUES ('00632038273', 'GBR', '88742653271', 'CHN');
INSERT INTO DELEGA (Delegato, SiglaDelegato, Delegante, SiglaDelegante) VALUES ('00876320409', 'ITA', '04917150155', 'ITA');
INSERT INTO DELEGA (Delegato, SiglaDelegato, Delegante, SiglaDelegante) VALUES ('04917150155', 'ITA', '00253475907', 'BEL');
INSERT INTO DELEGA (Delegato, SiglaDelegato, Delegante, SiglaDelegante) VALUES ('00963400156', 'NLD', '08657103288', 'CHL');




-- QUERY e PROCEDURE:

DROP VIEW IF EXISTS PaesiOperaiBarili;
DROP VIEW IF EXISTS AziendeClientiRiceventi;
DROP VIEW IF EXISTS TotalePacchiBolle;
DROP VIEW IF EXISTS ClientiDeleganti;
DROP VIEW IF EXISTS PartnerInScadenza;
DROP VIEW IF EXISTS NazioniAziende;
DROP PROCEDURE IF EXISTS StampaBolla;
DROP PROCEDURE IF EXISTS BolleContainerCosto;



-- 1) Vista che seleziona il Nome della NAZIONE, il Nome ed il Cognome degli OPERAI che hanno come paese d'origine tale nazione, ed il numero di bolle che 
-- prevedevano la spedizione di casse, la cui responsabilita' e' stata dei suddetti operai.
-- Nota: Si vogliono selezionare le informazioni appena citate, solamente se il numero di bolle e' di almeno 3.
CREATE VIEW PaesiOperaiBarili AS
( 
SELECT N.Nome AS NomeNazione, O.Nome AS NomeOperaio, O.Cognome AS CognomeOperaio, COUNT(*) AS NumBolle 

FROM NAZIONE N JOIN OPERAIO O ON (N.Sigla = O.NazioneNascita) JOIN RESPONSABILITA R ON (O.CF = R.Operaio) 
	JOIN BOLLA_DI_CARICO BDC ON (R.BollaDiCarico = BDC.NumeroDoc) 

WHERE EXISTS 
	(SELECT * FROM LISTA L WHERE L.BollaDiCarico = BDC.NumeroDoc AND L.Pacco = 'Cassa') 

GROUP BY N.Nome, O.Nome, O.Cognome HAVING NumBolle > 2 
);


-- 2) Vista che seleziona tutte le AZIENDE che non hanno un DEPOSITO, e che sono sia CLIENTI sia RICEVENTI. Di tali AZIENDE ci interessa sapere il Nome, 
-- la PartitaIVA, la SiglaPaese, ed un solo recapito TELEFONICO (con Prefisso e Numero nello stesso campo), il tutto ordinato in base al Nome aziendale.
CREATE VIEW AziendeClientiRiceventi AS
( 
SELECT DISTINCT A.Nome, A.PartitaIVA, A.SiglaPaese, NumeroTelefono(A.PartitaIVA, A.SiglaPaese) AS Telefono 

FROM CLIENTE C JOIN AZIENDA A ON (C.PartitaIVA = A.PartitaIVA AND C.SiglaPaese = A.SiglaPaese) JOIN TELEFONO T ON (A.PartitaIVA = T.PartitaIVA AND 
	A.SiglaPaese = T.NazionePossessore) JOIN RICEVENTE R ON (A.PartitaIVA = R.PartitaIVA AND A.SiglaPaese = R.SiglaPaese) 

WHERE NOT EXISTS 
	(SELECT * FROM DEPOSITO D WHERE D.Ricevente = A.PartitaIVA AND D.NazioneProprietario = A.SiglaPaese) 

ORDER BY A.Nome ASC 
);


-- 3) Vista che restituisce i NumeroDoc ed il totale degli Elementi delle BOLLE_DI_CARICO.
-- Nota: Tutte le BolleDiCarico che hanno tra gli operai responsabili un operaio con il Nome che inizia con la lettera 'M', non devono far parte del risultato.
CREATE VIEW TotalePacchiBolle AS
( 
SELECT BDC.NumeroDoc, SUM(L.Elementi) AS TotaleElementi 

FROM BOLLA_DI_CARICO BDC JOIN LISTA L ON (BDC.NumeroDoc = L.BollaDiCarico) 

WHERE NumeroDoc NOT IN 
	(SELECT BollaDiCarico FROM RESPONSABILITA R JOIN OPERAIO O ON (R.Operaio = O.CF) WHERE O.Nome LIKE 'M%') 

GROUP BY BDC.NumeroDoc 
);


-- 4) Vista che seleziona i Nomi e le E-Mail di tutte le AZIENDE CLIENTI che hanno svolto almeno una volta il ruolo di Delegante per un ordine di una 
-- BOLLA_DI_CARICO, e non hanno mai saldato il conto di una BOLLA_DI_CARICO intestata a loro tramite 'PayPal'.
CREATE VIEW ClientiDeleganti AS
( 
SELECT DISTINCT A.Nome, A.E_Mail 

FROM AZIENDA A JOIN CLIENTE C ON (A.PartitaIVA = C.PartitaIVA AND A.SiglaPaese = C.SiglaPaese) JOIN DELEGA D ON (C.PartitaIVA = D.Delegante AND 
	C.SiglaPaese = D.SiglaDelegante) JOIN BOLLA_DI_CARICO BDC ON (D.Delegato = BDC.Cliente AND D.SiglaDelegato = BDC.PaeseCliente) 

WHERE EXISTS 
	(SELECT * FROM BOLLA_DI_CARICO B WHERE D.Delegante = B.Cliente AND D.SiglaDelegante = B.PaeseCliente AND B.MetodoPagamento <> 'PayPal') 
);


-- 5) Vista che seleziona il Nome e l'eventuale Slogan di tutti i PARTNER che forniscono solo 'Camion', e la cui data di FineContratto scade entro 1 anno 
-- dalla data odierna.
CREATE VIEW PartnerInScadenza AS
( 
SELECT P.Nome, P.Slogan 

FROM PARTNER P 

WHERE (DATEDIFF(FineContratto, CURRENT_DATE) < 365) AND P.Nome NOT IN 
	(SELECT F.Partner FROM FORNITURA F WHERE F.Partner = P.Nome AND F.Mezzo <> 'Camion') 
);


-- 6) Vista che seleziona tutte le NAZIONI che sono il paese ospitante di un'AZIENDA CLIENTE che ha diritto a ricevere Sconti, oppure che e' stata Delegata 
-- almeno una volta da un'altra AZIENDA. Si mostrino: Nome e Sigla della NAZIONE, Nome e PartitaIVA dell'AZIENDA.
CREATE VIEW NazioniAziende AS
( 
SELECT N.Nome AS NomeNazione, N.Sigla, A.Nome AS NomeAzienda, A.PartitaIVA 

FROM NAZIONE N JOIN AZIENDA A ON (N.Sigla = A.SiglaPaese) 

WHERE EXISTS 
	(SELECT * FROM CLIENTE C WHERE C.PartitaIVA = A.PartitaIVA AND C.SiglaPaese = A.SiglaPaese AND C.Convenzionato = True) OR EXISTS 
	(SELECT * FROM DELEGA D WHERE D.Delegato = A.PartitaIVA AND D.SiglaDelegato = A.SiglaPaese) 
);


-- 7) Procedura che, dato in input un NumeroDoc di una BOLLA_DI_CARICO, restituisce tutti i dati ad essa reativi; al fine di creare la "versione cartacea" 
-- della suddetta bolla di carico.
DELIMITER |

CREATE PROCEDURE StampaBolla (IN numDoc VARCHAR(20))
BEGIN 
	(SELECT BDC.*, 
	A1.Nome AS NomeCliente, A2.Nome AS NomeRicevente, 
	NumeroTelefono(BDC.Cliente, BDC.PaeseCliente) AS TelCliente, NumeroTelefono(BDC.Ricevente, BDC.PaeseRicevente) AS TelRicevente, 
	
	CONCAT(A1.Via, ' - ', A1.Civico, ' - ', A1.CAP, ' - ', A1.Citta, ' - ', A1.SiglaPaese) AS IndirizzoCliente, 
	IndirizzoConsegnaRicevente(A2.PartitaIVA, A2.SiglaPaese) AS IndirizzoRicevente, 
	
	NumContainer(numDoc, DimContainer(BDC.Mezzo)) AS TotaleContainer, NumMezzi(NumContainer(numDoc, DimContainer(BDC.Mezzo)), BDC.Mezzo) AS TotaleMezzi, 
	CalcoloNumPacco(numDoc, 'Cassa') AS TotaleCasse, CalcoloNumPacco(numDoc, 'Barile') AS TotaleBarili, 
	CalcoloNumPacco(numDoc, 'Scatolone') AS TotaleScatoloni, CalcoloNumPacco(numDoc, 'Sacco') AS TotaleSacchi 
	
	FROM BOLLA_DI_CARICO BDC 
	JOIN CLIENTE C ON (BDC.Cliente=C.PartitaIVA AND BDC.PaeseCliente=C.SiglaPaese) 
	JOIN AZIENDA A1 ON (C.PartitaIVA=A1.PartitaIVA AND C.SiglaPaese=A1.SiglaPaese) 
	JOIN RICEVENTE R ON (BDC.Ricevente=R.PartitaIVA AND BDC.PaeseRicevente=R.SiglaPaese) 
	JOIN AZIENDA A2 ON (R.PartitaIVA=A2.PartitaIVA AND R.SiglaPaese=A2.SiglaPaese) 
	
	WHERE BDC.NumeroDoc = numDoc); 
END |

DELIMITER ;

-- Chiamata di procedura  -->  CALL StampaBolla('NumeroDoc_Bolla');


-- 8) Procedura che, dati in input un NumeroDiContainer, una Dimensione di CONTAINER, un CostoMinimo, ed un CostoMassimo, restituisce il NumeroDoc di tutte 
-- le BOLLE_DI_CARICO che hanno previsto l'impiego di un NumeroDiContainer della Dimensione passata come parametro, ed hanno un CostoTotale compreso 
-- tra i due valori CostoMinimo e CostoMassimo.
DELIMITER |

CREATE PROCEDURE BolleContainerCosto (IN numContain INT, IN dimen ENUM('Piccolo', 'Medio', 'Grande'), IN costoMin DECIMAL(15,2), IN costoMax DECIMAL(15,2))
BEGIN 
	(SELECT BDC.NumeroDoc FROM BOLLA_DI_CARICO BDC WHERE (NumContainer(NumeroDoc, dimen) = numContain) AND (DimContainer(BDC.Mezzo) = dimen) AND 
	(BDC.CostoTotale BETWEEN costoMin AND costoMax)); 
END |

DELIMITER ;

-- Chiamata di procedura  -->  CALL BolleContainerCosto(numeroContainer, 'Dimensione_Container', costoMinimo, costoMassimo);



-- END