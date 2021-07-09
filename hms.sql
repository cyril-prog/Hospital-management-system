--Drop table doctor if already existing
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE DOCTOR CASCADE CONSTRAINT PURGE';
	EXCEPTION
    WHEN OTHERS THEN
    NULL;
END;
/
--create table doctor
create table doctor(
doc_code varchar2(10 CHAR),
doc_name varchar2(60 CHAR) not null,
doc_gender varchar2(2 CHAR),
doc_dob date,
doc_age int,
doc_address varchar2(200 CHAR),
doc_designation varchar2(30 CHAR) not null,
doc_number number(11,0) not null,
fee numeric(6) not null,
constraint pk_doctor primary key (doc_code)
);
/

--procedure to calc age from dob
create or replace procedure cage(y in date,a out int) is
begin
if extract(month from sysdate)>extract(month from y) or (extract(month from sysdate)=extract(month from y) and extract(day from sysdate)>=extract(day from y)) then
a:=extract(year from sysdate)-extract(year from y);
else
a:=extract(year from sysdate)-extract(year from y)-1;
end if;
end;
/

--trigger to insert age
create or replace trigger finddoc_age 
before insert on doctor 
for each row
declare
y date:=:new.doc_dob;
a int;
begin
cage(y,a);
:new.doc_age:=a;
end;
/

--Drop table patient if already existing
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE PATIENT CASCADE CONSTRAINT PURGE';
	EXCEPTION
    WHEN OTHERS THEN
    NULL;
END;
/
--Create table patient
create table patient (
pat_id varchar2(10 CHAR),
pat_name varchar2(60 CHAR),
pat_gender varchar2(2 CHAR),
pat_dob date,
pat_age int,
pat_doj date,
pat_address varchar2(200 CHAR),
pat_number number(11,0),
pat_doc_code varchar2(10 CHAR),
constraint pk_patient primary key (pat_id),
constraint fk_pat_doc_code foreign key(pat_doc_code)
references doctor(doc_code)
);
/
--trigger to insert age
create or replace trigger findpat_age 
before insert on patient 
for each row
declare
y date:=:new.pat_dob;
a int;
begin
cage(y,a);
:new.pat_age:=a;
end;
/

--Drop table patient_diagnosis if already existing
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE PATIENT_DIAGNOSIS CASCADE CONSTRAINT PURGE';
	EXCEPTION
    WHEN OTHERS THEN
    NULL;
END;
/
--Create table patient_diagnosis
create table patient_diagnosis(
Diag_ID varchar2(10 CHAR),
diag_details varchar2(200 CHAR),
diag_remarks varchar2(200 CHAR),
pat_id varchar2(10 CHAR),
diag_amount numeric(19,9),
constraint pk_patient_diagnosis primary key  (diag_id),
constraint fk_pat_id foreign key (pat_id)
references patient(pat_id)
);
/

--Drop table total if already existing
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE TOTAL CASCADE CONSTRAINT PURGE';
	EXCEPTION
    WHEN OTHERS THEN
    NULL;
END;
/

--create table total
CREATE TABLE TOTAL(
bill_no int primary key,
pat_id varchar2(10 CHAR),
TOTAL_amount NUMBER(10),
constraint fk_pat_idt foreign key (pat_id)
references patient(pat_id)
);
/

--trigger to calc total_amount and assign bill_no
CREATE OR REPLACE TRIGGER T_TRG
before INSERT ON TOTAL
FOR EACH ROW
DECLARE
DOC_ID VARCHAR(10 CHAR);
k int;
y int;
d date;
BEGIN
SELECT diag_amount INTO k FROM patient_diagnosis where pat_id=:new.pat_id;
select pat_doj,pat_doc_code into d,doc_id from patient where pat_id=:new.pat_id;
select fee into y from doctor where doc_id=doc_code;
:new.total_amount:=y+k*(trunc(sysdate-d));
if :new.total_amount=0 then :new.total_amount:=y+k;
end if;
if :new.total_amount>0 then
select BILL_NO_SEQ.NEXTVAL into :new.bill_no from dual; 
end if;
end;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE BILL_NO_SEQ';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE!= -2289 THEN
            RAISE;
            END IF;
END;
/

CREATE SEQUENCE BILL_NO_SEQ
  MINVALUE 1
  MAXVALUE 100000
  START WITH 1
  INCREMENT BY 1;
/

--Drop VIEW bill if already existing
BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW BILL CASCADE CONSTRAINT PURGE';
	EXCEPTION
    WHEN OTHERS THEN
    NULL;
END;
/
--create view bill
create OR REPLACE view bill as
select BILL_NO,pat_name,pat_gender,pat_address,doc_name,total_amount 
from(select BILL_NO,pat_name,pat_gender,pat_address,total_amount,pat_doc_code from patient inner join total on total.pat_id=patient.pat_id) inner join doctor on pat_doc_code=doctor.doc_code;
