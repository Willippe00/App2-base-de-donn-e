create schema Problematique;

set search_path = Problematique, pg_catalog;

CREATE TABLE Universite
(
   universiteID INT NOT NULL,
   nomUniversite varchar(64) NOT NULL,
   PRIMARY KEY (universiteID)
);

CREATE TABLE Faculte
(
   faculteID INT NOT NULL,
   nomFaculte VARCHAR(255) NOT NULL,
   universiteID INT NOT NULL,
   PRIMARY KEY (faculteID),
   FOREIGN KEY (universiteID) REFERENCES Universite(universiteID)
);

CREATE TABLE Departement
(
   departementID INT NOT NULL,
   nomDepartement VARCHAR(255) NOT NULL,
   faculteID INT NOT NULL,
   PRIMARY KEY (departementID),
   FOREIGN KEY (faculteID) REFERENCES Faculte(faculteID)
);

CREATE TABLE Personnel
(
   cip VARCHAR(255) NOT NULL,
   departementID INT NOT NULL,
   RoleID int not null ,
   PRIMARY KEY (cip),

   FOREIGN KEY (departementID) REFERENCES Departement(departementID)
);

CREATE TABLE Campus
(
   campusID INT NOT NULL,
   nomCampus VARCHAR(255) NOT NULL,
   universiteID INT NOT NULL,
   PRIMARY KEY (campusID),
   FOREIGN KEY (universiteID) REFERENCES Universite(universiteID)
);

CREATE TABLE Pavillon
(
   pavillonID INT NOT NULL,
   nomPavillon VARCHAR(255) NOT NULL,
   campusID INT NOT NULL,
   PRIMARY KEY (pavillonID),
   FOREIGN KEY (campusID) REFERENCES Campus(campusID)
);

CREATE TABLE Local
(
   nomLocal VARCHAR(255) NOT NULL,
   capacite INT NOT NULL,
   fonctionID INT NOT NULL,
   caracteristiqueID INT NOT NULL,
   note VARCHAR(255) NOT NULL,
   pavillonID INT NOT NULL,
   Père VARCHAR(255) NULL,
   PRIMARY KEY (nomLocal),
   FOREIGN KEY (pavillonID) REFERENCES Pavillon(pavillonID),
   FOREIGN KEY (nomLocal) REFERENCES Local(nomLocal)
);

CREATE TABLE Reservation
(
   reservationID serial NOT NULL,
   heureDebit time NOT NULL,
   heureFin time NOT NULL,
   categorie CHAR NOT NULL,
   cip CHAR NOT NULL,
   nomLocal CHAR NOT NULL,
   PRIMARY KEY (reservationID),
   FOREIGN KEY (cip) REFERENCES Personnel(cip),
   FOREIGN KEY (nomLocal) REFERENCES Local(nomLocal)
);

CREATE TABLE Role
(

   RoleID int not NULL,
   Role_name VARCHAR(255) not NULL,
   tempReservation time not Null,
   Peutdelete Boolean not null


);

CREATE TABLE Event
(
   codeEvent int not NULL,
   descEvent VARCHAR(250) not NULL,
   PRIMARY KEY (codeEvent)
);

CREATE TABLE Logbook
(
   numLog serial not NULL,
   reservationID int not NULL,
   codeEvent int not NULL,
   date date not NULL,
   PRIMARY KEY (numLog),
   FOREIGN KEY (reservationID) REFERENCES Reservation(reservationID),
   FOREIGN KEY (codeEvent) REFERENCES Event(codeEvent)
);



insert into  Universite VALUES (1,'Université de Sherbrooke');

insert into Faculte VALUES (1, 'Droit',1);
insert into Faculte VALUES (2, 'École de gestion',1);
insert into Faculte VALUES (3, 'Éducation',1);
insert into Faculte VALUES (4, 'Génie',1);
insert into Faculte VALUES (5, 'Lettres et sciences humaines',1);
insert into Faculte VALUES (6, 'École de musique',1);
insert into Faculte VALUES (7, 'Sciences de l,activité physique',1);

insert into Departement values (1,'Génie électrique et Génie informatique',4);
insert into Departement values (2,'Génie mécanique',4);
insert into Departement values (3,'Génie chimique et biotechnologie',4);
insert into Departement values (4,'Génie civil et du bâtiment',4);

insert into Personnel values ('Robw1901', 1, 1);
insert into Personnel values ('CarV0701', 1, 2);
insert into Personnel values ('hutv8692', 1, 3);
insert into Personnel values ('lebz4532', 1, 4);

insert into Campus values (1, 'Campus principal',1);
insert into Campus values (2, 'Campus de Longueuil',1);

insert into Pavillon values (1, 'C1', 1);
insert into Pavillon values (2, 'C2', 1);
insert into Pavillon values (3, 'D7', 1);

insert into Role values (1,'Étudiant' ,NOW() + interval '24 hours', false);
insert into Role values (2,'Enseignant' ,interval '24 hours', false);
insert into Role values (3,'Personnel de soutien' ,now(), false);
insert into Role values (4,'Administrateur' , interval '1 year', true);

insert into Local values ('1007' , 21,0212, 1,'Grand',1);
insert into Local values ('2018' , 10,0212, 1,'Matériaux composite',1, null);






CREATE OR REPLACE FUNCTION inserer_reservation(p_date_debut DATE, p_date_fin DATE,p_categorie VARCHAR(255) , p_nom_local VARCHAR(255), p_personne_cip INT)
   RETURNS VOID AS $$
BEGIN
   -- Vérifier si le local est disponible pour la période spécifiée
   IF EXISTS (
      SELECT 1
      FROM reservation
      WHERE nomLocal = p_nom_local
        AND (p_date_debut BETWEEN heureDebit AND heureFin OR p_date_fin BETWEEN heureDebit AND heureFin)
   ) THEN
      RAISE EXCEPTION 'Le local est déjà réservé pour cette période.';
   END IF;

   -- Vérifier si la personne a le rôle nécessaire
   IF NOT EXISTS (
      SELECT 1
      FROM personnel
      WHERE cip  = p_personne_cip
        AND RoleID = 1 or 4
   ) THEN
      RAISE EXCEPTION 'La personne n_a pas le rôle requis pour effectuer la réservation.';
    END IF;

   -- Vérifier si le parent sont non réserver
   IF exists(
      select 1
      from Reservation
      where (select Père from Local where Local.nomLocal = p_nom_local and Père != null)

       -- fini

   )then
      RAISE EXCEPTION 'Le parent est déjà réserver.';
   end if;

   -- vérifier si les enfant sont réserver
   if exists(
      select 1
      from Reservation
      where (select nomLocal from Local where Père = p_nom_local)
      -- fini
   )
   then
      RAISE EXCEPTION 'L,enfant est déjà réserver.';
   end if;

    -- Insérer la réservation
   insert into Reservation values (reservationID , p_date_debut, p_date_fin,p_categorie ,p_personne_cip,p_nom_local );
   insert into Event values (0, 'Création');

   end
    --VALUES (p_date_debut, p_date_fin, p_nom_local, p_personne_id);

    -- Afficher un message de confirmation
    --RAISE NOTICE 'La réservation a été effectuée avec succès.';

    -- Autres actions à effectuer après l'insertion de la réservation

$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION validate_delete(p_cip VARCHAR(255), nomLocal_reserver VARCHAR(255), heuredébut TIME)
   RETURNS VOID AS
$$
BEGIN
   IF EXISTS (
      SELECT 1
      FROM Personnel
      WHERE Personnel.cip = p_cip
        AND RoleID = 4
   )
   AND exists (
       select 1
       from Reservation
       where Reservation.heureDebit = heuredébut
       and Reservation.nomLocal = nomLocal_reserver
         )
       THEN
      delete  from Reservation
      where Reservation.heureDebit = heuredébut
       and Reservation.nomLocal = nomLocal_reserver;


   ELSE
      RAISE EXCEPTION 'Vous n''avez pas les autorisations nécessaires pour supprimer cette réservation.';
   END IF;

   delete from Reservation where nomLocal = nomLocal_reserver and heureDebit = heuredébut;
   insert into Event values (2, 'Annulation');

END;
   $$
   LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION afficher_resultats()
   RETURNS VOID AS $$
DECLARE
   row_reservation Reservation; -- Déclaration de la variable de type record
BEGIN
   RAISE NOTICE 'Résultats de la requête :';

   FOR row_reservation IN
      SELECT nomLocal, heureDebit, heureFin
      FROM Reservation
      LOOP
           RAISE NOTICE 'Date de début : %, Nom du local : %, Date de fin : %',
              row_reservation.heureDebit, row_reservation.nomLocal, row_reservation.heureFin;
      END LOOP;

   RAISE NOTICE 'Fin des résultats.';
END;
$$ LANGUAGE plpgsql;



select inserer_reservation()


