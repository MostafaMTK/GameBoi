
# GameBOI – Game Console using STM32 & ARM Assembly

GameBOI is a retro-style game console built from scratch as a course project at Cairo University. Using only low-level ARM Assembly on the STM32F401RCT6 microcontroller, we recreated the feel of a classic Game Boy with 4 unique games, a physical interface, and real-time graphics.

## 🎮 Games Included
1. **Tic-Tac-Toe (XO)**
   - Two-player and player-vs-AI modes.
   - Grid rendering, input validation, and win/draw detection.

2. **Pong**
   - Two-player paddle game with real-time collision and scoring logic.
   - Screen redraw and ball physics implemented in Assembly.

3. **Swords Bound**
   - Combat-style side-scroller with health bars, lives, hit detection, animations, and round logic.
   - Dynamic sprite handling using TFT image sequences.

4. **Whack-A-Mole**
   - A fast-paced game where a mole appears in random locations and the player must hit it quickly.
   - Timing-based logic and rapid user input handling.

## 🛠 Technologies
- **Microcontroller**: STM32F401RCT6 (Black Pill Board)
- **Display**: 3.5" TFT ILI9486 (320x480)
- **Programming Language**: ARM Assembly (Keil IDE)
- **Simulation Tools**: Proteus
- **Asset Tools**: Python for converting graphics

## 📷 Hardware Setup
- TFT connected via 8-bit parallel GPIO.
- Buttons wired for directional input and game actions.
- ST-Link v2 debugger for flashing and debugging.

## 🧩 Code Architecture
- **Modular Assembly Design**: each game has its own loop and input/draw/logic handlers.
- **Debounced Input**: custom input stabilization routines.
- **Custom Rendering Engine**: low-level routines to render pixels, draw shapes, and animate sprites.

## 🚀 Future Enhancements
- Touch screen support.
- External memory to support more games/themes.
- Joystick integration.
- Sound effects via buzzer.

## 👨‍💻 Contributors
- Mostafa Mohammed
- Muslim Ahmed
- Ahmed Maged
- Mariam Mohammed
- Mariam Sameh
- Anne Omer
- Alaa Tarek
- Habiba Mahmoud

## 📽️ Demo
Check out the full project demo on [LinkedIn](https://www.linkedin.com/posts/mostafamohammed2005_we-built-a-gameboy-from-scratch-as-part-activity-7327661472514236416-UyNr).
