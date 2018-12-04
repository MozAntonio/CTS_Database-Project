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


