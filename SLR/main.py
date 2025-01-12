import sys
from parser import Parser
from pprint import pprint

EXIT_SEQ: str = "exit"

if __name__ == "__main__":
    if len(sys.argv) == 3:
        grammar_file = sys.argv[1]
        fip_file = sys.argv[2]
        parser = Parser(grammar_file, is_code_file=True)
        ok, result = parser.parse(fip_file)
        
        if not ok:
                print("[ERROR] Invalid sequence. Please try again.\n")
                print(result)
        else:
            print("[OK] Sequence parsed successfully.")
            for idx, transition in enumerate(result):
                print(f"Transition {idx + 1}: {transition}")
        
        print(f"Parsed: {grammar_file} and {fip_file}")
        sys.exit(0)
    
    parser = Parser()
    
    while True:
        try:
            print()
            input_seq = input("Enter a sequence to parse ('exit' to leave): ").strip()
            
            if input_seq ==  EXIT_SEQ:
                print("Exiting...")
                break

            ok, result = parser.parse(input_seq)

            if not ok:
                print("[ERROR] Invalid sequence. Please try again.\n")
                print(result)
            else:
                print("[OK] Sequence parsed successfully.")
                for idx, transition in enumerate(result):
                    print(f"Transition {idx + 1}: {transition}")
        except Exception as e:
            print(f"Error: {e}")
            sys.exit(1)
        finally:
            if input_seq == EXIT_SEQ:
                break
    
    sys.exit(0)
