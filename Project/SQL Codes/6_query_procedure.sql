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


