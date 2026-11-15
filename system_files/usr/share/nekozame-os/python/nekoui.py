"""nekozame's controller-friendly ui pieces (pygame): the palette, input from a
controller, keyboard, mouse or touch, the look (the underwater loop behind a plum
veil) and an on-screen keyboard. nekozame-steam-art uses the palette; nekozame-firstboot has
its own copy.
"""
import os
import subprocess
import time

os.environ.setdefault("PYGAME_HIDE_SUPPORT_PROMPT", "1")
import pygame  # noqa: E402

ROOT = os.environ.get("NEKOZAME_ROOT", "")  # for trying it out of the image
FRAMES = ROOT + "/usr/share/plymouth/themes/nekozame/frames-16x10/frame-{}.png"
LOGO = ROOT + "/usr/share/icons/hicolor/256x256/apps/nekozame.png"

# the nekozame palette
PLUM, PANEL, DEEP, RAISED = (90, 79, 110), (79, 69, 98), (67, 58, 85), (104, 92, 127)
PINK, SOFT, WHITE, DIM = (255, 192, 229), (255, 212, 238), (255, 255, 255), (179, 167, 203)
MINT, BUTTER, ROSE, BLUE = (200, 247, 220), (255, 241, 176), (255, 179, 200), (184, 228, 255)


def sh(*cmd, timeout=None):
    """run a command, return (ok, output)."""
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode == 0, (r.stdout + r.stderr).strip()
    except (OSError, subprocess.TimeoutExpired) as e:
        return False, str(e)


# --- input: one set of actions from a controller, keyboard, mouse or touch ----------

UP, DOWN, LEFT, RIGHT, OK, BACK, DEL, START = "up", "down", "left", "right", "ok", "back", "del", "start"
PAUSE, PREV, NEXT, MORE = "pause", "prev", "next", "more"  # y, l1, r1, x


class Input:
    def __init__(self):
        self.pads = []
        try:
            from pygame._sdl2 import controller
            controller.init()
            for i in range(controller.get_count()):
                if controller.is_controller(i):
                    self.pads.append(controller.Controller(i))
        except Exception:
            pygame.joystick.init()
            for i in range(pygame.joystick.get_count()):
                self.pads.append(pygame.joystick.Joystick(i))
        self.stick = 0.0
        self.stick_y = 0.0
        self.next_repeat = 0.0

    def actions(self, events):
        """turn pygame events into actions (and typed text, and clicks)."""
        acts, text, clicks = [], "", []
        for e in events:
            if e.type == pygame.KEYDOWN:
                k = {pygame.K_UP: UP, pygame.K_DOWN: DOWN, pygame.K_LEFT: LEFT, pygame.K_RIGHT: RIGHT,
                     pygame.K_RETURN: OK, pygame.K_KP_ENTER: OK, pygame.K_ESCAPE: BACK,
                     pygame.K_BACKSPACE: DEL, pygame.K_TAB: DOWN, pygame.K_F5: PAUSE,
                     pygame.K_PAGEUP: PREV, pygame.K_PAGEDOWN: NEXT}.get(e.key)
                if k:
                    acts.append(k)
                elif e.unicode and e.unicode.isprintable():
                    text += e.unicode
            elif e.type == getattr(pygame, "CONTROLLERBUTTONDOWN", -1):
                k = {pygame.CONTROLLER_BUTTON_DPAD_UP: UP, pygame.CONTROLLER_BUTTON_DPAD_DOWN: DOWN,
                     pygame.CONTROLLER_BUTTON_DPAD_LEFT: LEFT, pygame.CONTROLLER_BUTTON_DPAD_RIGHT: RIGHT,
                     pygame.CONTROLLER_BUTTON_A: OK, pygame.CONTROLLER_BUTTON_B: BACK,
                     pygame.CONTROLLER_BUTTON_X: DEL, pygame.CONTROLLER_BUTTON_START: START,
                     pygame.CONTROLLER_BUTTON_Y: PAUSE, pygame.CONTROLLER_BUTTON_LEFTSHOULDER: PREV,
                     pygame.CONTROLLER_BUTTON_RIGHTSHOULDER: NEXT}.get(e.button)
                if k:
                    acts.append(k)
            elif e.type == getattr(pygame, "CONTROLLERAXISMOTION", -1):
                v = e.value / 32767
                if e.axis == pygame.CONTROLLER_AXIS_LEFTX:
                    self.stick = v
                elif e.axis == pygame.CONTROLLER_AXIS_LEFTY:
                    self.stick_y = v
            elif e.type == pygame.JOYHATMOTION:
                x, y = e.value
                acts += [LEFT] if x < 0 else [RIGHT] if x > 0 else []
                acts += [UP] if y > 0 else [DOWN] if y < 0 else []
            elif e.type == pygame.JOYBUTTONDOWN and not hasattr(pygame, "CONTROLLERBUTTONDOWN"):
                acts += {0: [OK], 1: [BACK], 2: [DEL], 7: [START]}.get(e.button, [])
            elif e.type == pygame.MOUSEBUTTONDOWN and e.button == 1:
                clicks.append(e.pos)
            elif e.type == pygame.FINGERDOWN:
                w, h = pygame.display.get_surface().get_size()
                clicks.append((int(e.x * w), int(e.y * h)))
        # the stick, with a repeat while it's held
        now = time.time()
        held = UP if self.stick_y < -0.6 else DOWN if self.stick_y > 0.6 else LEFT if self.stick < -0.6 \
            else RIGHT if self.stick > 0.6 else None
        if held and now >= self.next_repeat:
            acts.append(held)
            self.next_repeat = now + 0.18
        elif not held:
            self.next_repeat = 0.0
        return acts, text, clicks


# --- drawing --------------------------------------------------------------------------

class Look:
    def __init__(self, screen):
        self.screen = screen
        self.w, self.h = screen.get_size()
        self.s = self.h / 800  # everything is laid out for the deck's 1280x800
        font = sh("fc-match", "-f", "%{file}", "Noto Sans:bold")[1] or None
        regular = sh("fc-match", "-f", "%{file}", "Noto Sans")[1] or None
        self.big = pygame.font.Font(font, int(44 * self.s))
        self.mid = pygame.font.Font(font, int(26 * self.s))
        self.text = pygame.font.Font(regular, int(21 * self.s))
        self.small = pygame.font.Font(regular, int(17 * self.s))
        self.frames = []
        for i in range(48):
            try:
                self.frames.append(pygame.image.load(FRAMES.format(i)).convert())
            except (pygame.error, FileNotFoundError):
                break
        try:
            logo = pygame.image.load(LOGO).convert_alpha()
            n = int(150 * self.s)
            self.logo = pygame.transform.smoothscale(logo, (n, n))
        except (pygame.error, FileNotFoundError):
            self.logo = None
        self.veil = pygame.Surface((self.w, self.h), pygame.SRCALPHA)
        self.veil.fill((40, 32, 54, 195))

    def background(self, t):
        if self.frames:
            f = self.frames[int(t * 16) % len(self.frames)]
            self.screen.blit(pygame.transform.scale(f, (self.w, self.h)), (0, 0))
        else:
            self.screen.fill(PLUM)
        self.screen.blit(self.veil, (0, 0))

    def panel(self, rect, fill=PANEL, border=None, radius=18, alpha=235):
        surf = pygame.Surface(rect.size, pygame.SRCALPHA)
        pygame.draw.rect(surf, fill + (alpha,), surf.get_rect(), border_radius=int(radius * self.s))
        if border:
            pygame.draw.rect(surf, border, surf.get_rect(), width=max(2, int(2 * self.s)), border_radius=int(radius * self.s))
        self.screen.blit(surf, rect.topleft)

    def label(self, text, font, color, pos, center=False):
        img = font.render(text, True, color)
        r = img.get_rect()
        if center:
            r.midtop = pos
        else:
            r.topleft = pos
        self.screen.blit(img, r)
        return r

    def hint(self, text):
        self.label(text, self.small, DIM, (self.w // 2, self.h - int(40 * self.s)), center=True)

    def title(self, text, sub=None):
        y = int(50 * self.s)
        self.label(text, self.big, PINK, (self.w // 2, y), center=True)
        if sub:
            self.label(sub, self.text, WHITE, (self.w // 2, y + int(64 * self.s)), center=True)


def show_in_game_mode():
    """game mode shows the windows steam tells it to, by app id (769 is steam's own
    interface): this window says it's 769, and if nothing's set yet, so does the screen."""
    import shutil
    wid = pygame.display.get_wm_info().get("window")
    if not wid or not shutil.which("xprop"):
        return
    sh("xprop", "-id", str(wid), "-f", "STEAM_GAME", "32c", "-set", "STEAM_GAME", "769")
    ok, out = sh("xprop", "-root", "GAMESCOPECTRL_BASELAYER_APPID")
    if not ok or "not found" in out or "=" not in out:
        sh("xprop", "-root", "-f", "GAMESCOPECTRL_BASELAYER_APPID", "32c", "-set", "GAMESCOPECTRL_BASELAYER_APPID", "769")


class Keyboard:
    """an on-screen keyboard you can use with the d-pad. handle() gives ("done", text)
    or "cancel"."""
    LOWER = ["1234567890", "qwertyuiop", "asdfghjkl-", "zxcvbnm_.@"]
    UPPER = ["!\"#$%&/()=", "QWERTYUIOP", "ASDFGHJKL+", "ZXCVBNM;:?"]
    SPECIAL = ["shift", "space", "delete", "done"]

    def __init__(self, title, value="", secret=False):
        self.title, self.value, self.shift, self.show = title, value, False, not secret
        self.row, self.col = 1, 0

    def keys(self):
        rows = [list(r) for r in (self.UPPER if self.shift else self.LOWER)]
        return rows + [self.SPECIAL]

    def draw(self, look, t):
        look.title(self.title)
        box = pygame.Rect(int(look.w * 0.2), int(150 * look.s), int(look.w * 0.6), int(60 * look.s))
        look.panel(box, DEEP, PINK)
        shown = self.value if self.show else "•" * len(self.value)
        look.label(shown + ("|" if int(t * 2) % 2 == 0 else ""), look.mid, WHITE, (box.x + int(20 * look.s), box.y + int(12 * look.s)))
        kw, kh, gap = int(80 * look.s), int(64 * look.s), int(10 * look.s)
        top = int(250 * look.s)
        self.rects = []
        for r, row in enumerate(self.keys()):
            wide = r == 4
            width = (kw * 10 + gap * 9 - gap * 3) // 4 if wide else kw
            x0 = look.w // 2 - (len(row) * (width + gap) - gap) // 2
            for c, k in enumerate(row):
                rect = pygame.Rect(x0 + c * (width + gap), top + r * (kh + gap), width, kh)
                self.rects.append((r, c, rect))
                on = (r, c) == (self.row, self.col)
                special_on = (k == "shift" and self.shift)
                look.panel(rect, PINK if on else RAISED if not special_on else SOFT, None, radius=12)
                look.label(k, look.mid if len(k) == 1 else look.text, DEEP if on or special_on else WHITE,
                           (rect.centerx, rect.y + int(16 * look.s)), center=True)
        look.hint("A: type   X: delete   B: back   Start: done   (a keyboard works too)")

    def press(self, k):
        if k == "shift":
            self.shift = not self.shift
        elif k == "space":
            self.value += " "
        elif k == "delete":
            self.value = self.value[:-1]
        elif k == "done":
            return ("done", self.value)
        else:
            self.value += k
        return None

    def handle(self, acts, text, clicks, look):
        rows = self.keys()
        if UP in acts:
            self.row = (self.row - 1) % len(rows)
        if DOWN in acts:
            self.row = (self.row + 1) % len(rows)
        self.col = min(self.col, len(rows[self.row]) - 1)
        if LEFT in acts:
            self.col = (self.col - 1) % len(rows[self.row])
        if RIGHT in acts:
            self.col = (self.col + 1) % len(rows[self.row])
        self.value += text
        if DEL in acts:
            self.value = self.value[:-1]
        if START in acts:
            return ("done", self.value)
        if BACK in acts:
            return "cancel"
        for pos in clicks:
            for r, c, rect in getattr(self, "rects", []):
                if rect.collidepoint(pos):
                    self.row, self.col = r, c
                    return self.press(rows[r][c])
        if OK in acts:
            # enter on a real keyboard connects; A on the pad types the key
            if pygame.key.get_pressed()[pygame.K_RETURN]:
                return ("done", self.value)
            return self.press(rows[self.row][self.col])
        return None


