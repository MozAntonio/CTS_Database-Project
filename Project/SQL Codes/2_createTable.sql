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