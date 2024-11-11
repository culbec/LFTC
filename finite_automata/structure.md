# Finite Automata Internal Structure

## States

1. **q0**: `stare initiala`. Face tranzitia la urmatoarele reprezentari: _decimal, octal, binar, hexadecimal_;
2. **q1**: `stare decimal initiala/finala`. Cifre de la 0-9. Tranzitie spre **q1**;
3. **q2**: `stare octal intiala/finala`. Reprezentarea _octala_ a numarului: cifre de la 0-7;
4. **q3**: `stare de tranzitie spre binar/hexadecimal`. Face trecerea la reprezentari binare/hexadecimale;
5. **q4**: `stare binar initiala`. b sau B. Tranzitie spre **q5**;
6. **q5**: `stare binar finala`. 0 sau 1. Tranzitie spre **q5**;
7. **q6**: `stare hexadecimal initiala`. x sau X. Tranzitie spre **q7**;
8. **q7**: `stare hexadecimal intermediar`. 0-F. Asigura reprezentarea numarului in `nibbles`. Tranzitie spre **q8**;
9. **q8**: `stare hexadecimal final`. 0-F. Tranzitie spre **q7**;
10. **q9**: `stare initiala/finala unsigned`. _u_ sau _U_. Tranzitie spre **q11**;
11. **q10**: `stare initiala/finala long`. _l_, _ll_, sau _L_, _LL_. Tranzitie spre **q11**;
12. **q11**: `stare finala`. Finalul. **q9** -> _l_, _ll_, _L_, _LL_; **q10** -> _u_, _U_.
