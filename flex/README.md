# Flex for Windows

Install `winflexbison3` using `Chocolatey` with the following command: `choco install winflexbison3`.

Compile the lexer file with the following command: `win_flex -+ --wincompat -o <output_file>.cpp <lexer_file>.l`.

Compile the resulted file with the following command: `g++ <lexer>.cpp -I <path_of_winflexbison3_installation>\tools -o <output_file>`.

Run the resulted file with the following command: `<output_file> <input_file>`.

## Notes

- run `choco info winflexbison3` to get the installation path of `winflexbison3`.
