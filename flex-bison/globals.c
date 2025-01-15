#include "flexer.h"

Analyzer *analyzer = NULL;
bool hasErrors = false;
bool lastTokenWasSeparator = false;
int ts_id = 0;
int ts_const = 0;
int ts_pos = -1;
int fip_pos = 0;
int exceptions_pos = 0;
uint32_t currLine = 1;