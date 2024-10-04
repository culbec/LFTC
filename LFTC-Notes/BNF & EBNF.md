Descriu logic, standardizat, sintaxa unui limbaj.
## BNF (Backus-Naur form)
- simboluri de baza (_**primitive**_) sau simboluri terminale: _cuvinte cheie_, _operatori_, _separatori_, cuvinte specifice limbajului;
- variabile metalingvistice: **simboluri neterminale**, specifica _**constructii ale limbajelor**_, si se afla intre _<>_;
- conective: ::= (egal) si | (alternative);

_Exemplu_: numere intregi
- <intreg\> ::= <intreg_fara_semn\> | + \<intreg_fara_semn\> | - <intreg_fara_semn\>
- <intreg_fara_semn\> ::= <cifra\> | <cifra\><intreg_fara_semn\> (recursiv), se apeleaza pana la epuizarea regulii;
- <cifra\> ::= 0|1|...|9 -> epuizarea regulii;
## EBNF (Extended Backus-Naur form)
- _**neterminalele**_ se scriu ca si cuvinte, fara <\>;
- _**terminalele**_ sunt scrise intre " si de obicei cu MAJUSCULE: "BEGIN";
- | - alternanta;
- [optional\];
- (grupare);
- {repetare_optionala} -> 0..n;
- = in loc de ::=;
- . -> sfarsit de regula;

_Exemplu_: numere intregi
- IntregFaraSemn = Semn IntregFaraSemn;
- IntregFaraSemn = Cifra{Cifra};
- Cifra = "0" | "1" | ... | "9";