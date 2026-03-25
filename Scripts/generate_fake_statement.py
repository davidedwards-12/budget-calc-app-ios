"""
Generates a fake Eastman Credit Union-style bank statement PDF for testing BudgetCalc.
Usage: python3 generate_fake_statement.py
Output: fake_ecu_statement.pdf (in the same directory)
"""

from fpdf import FPDF
from fpdf.enums import XPos, YPos

# ---------------------------------------------------------------------------
# Fake data
# ---------------------------------------------------------------------------

MEMBER_NUMBER = "00000000"
STATEMENT_DATE = "01/31/26"
MEMBER_NAME = ["JOHN A TESTUSER", "JANE B TESTUSER"]
ADDRESS = ["123 FAKE STREET", "ANYTOWN TN 00000-0000"]

SAVINGS_ACCOUNT = {
    "name": "Primary Share Account",
    "number": "XXXXXXX00001",
    "starting_balance": 4200.00,
    "transactions": [
        ("01-01", "Starting Balance",                               None,       None,       4200.00),
        ("01-05", "W/D Internet Transfer to 100000002 CK",          None,       -500.00,    3700.00),
        ("01-14", "Deposit Internet Transfer from 100000002 CK",    1200.00,    None,       4900.00),
        ("01-26", "Extraordinary Dividend Extraordinary Dividend",   8.75,       None,       4908.75),
        ("01-28", "Deposit Internet Transfer from 100000002 CK",    1200.00,    None,       6108.75),
        ("01-30", "Eff. 01-31 Credit Dividend",                     1.05,       None,       6109.80),
    ],
    "ytd_div": "9.80",
    "balance": "6,109.80",
    "div_rate": "0.300",
}

CHECKING_ACCOUNT = {
    "name": "Beyond Free Checking Account",
    "number": "XXXXXXX00002",
    "starting_balance": 980.00,
    "transactions": [
        ("01-01",  "Starting Balance",                                          None,       None,       980.00),
        ("01-02",  "POS W/D WAL-MART #0710 4424 LEBANON PIKE HERMITAGE TNUS",  None,       -62.14,     917.86),
        ("01-02",  "POS W/D ZAXBY'S #45501 HERMITAGE TNUS",                    None,       -11.37,     906.49),
        ("01-02",  "Ext Deposit VENMO - CASHOUT",                               40.00,      None,       946.49),
        ("01-05",  "POS W/D CHICK-FIL-A #01764 HERMITAGE TNUS",                None,       -18.45,     928.04),
        ("01-05",  "POS W/D TST* JACK BROWN'S JOINT NASHVILLE TNUS",           None,       -44.07,     883.97),
        ("01-05",  "POS W/D KILWINS 0134 FRANKLIN TNUS",                       None,       -31.50,     852.47),
        ("01-05",  "Deposit Internet Transfer from 100000001 SAV",              500.00,     None,       1352.47),
        ("01-05",  "POS W/D NASHVILLE MLS SOCCER 615-000-0000 TNUS",           None,       -44.00,     1308.47),
        ("01-06",  "POS W/D APPLE.COM/BILL 866-712-7753 CAUS",                 None,       -0.99,      1307.48),
        ("01-07",  "POS W/D WALMART.COM 8009256 702 SW 8TH ST BENTONVILLE AR", None,       -54.22,     1253.26),
        ("01-08",  "POS W/D APPLE.COM/BILL 866-712-7753 CAUS",                 None,       -16.99,     1236.27),
        ("01-12",  "POS W/D CHICK-FIL-A #01764 615-889-2177 TNUS",             None,       -28.50,     1207.77),
        ("01-12",  "POS W/D LA HACIENDA MEXICAN RES NASHVILLE TNUS",           None,       -39.80,     1167.97),
        ("01-12",  "Ext W/D TARGET CARD SRVC - PAYMENT",                       None,       -150.00,    1017.97),
        ("01-14",  "Ext Deposit FAKE EMPLOYER INC 9999999999 - PAYROLL",        2800.00,    None,       3817.97),
        ("01-14",  "W/D Internet Transfer to 100000001 SAV",                   None,       -1200.00,   2617.97),
        ("01-15",  "Ext W/D AMERICANEXPRESS PERSONAL SAVINGS - TRANSFER",      None,       -600.00,    2017.97),
        ("01-16",  "POS W/D MCDONALD'S F7397 545 DONELSON PIKE NASHVILLE TN",  None,       -14.22,     2003.75),
        ("01-16",  "POS W/D NES ELECTRIC BILLPAY - BILLPAY",                   None,       -122.00,    1881.75),
        ("01-20",  "POS W/D CHICK-FIL-A APP 866-232-2040 GAUS",               None,       -10.00,     1871.75),
        ("01-20",  "POS W/D WM SUPERCENTER #710 4424 LEBANON PIKE TN",         None,       -74.13,     1797.62),
        ("01-20",  "POS W/D PARKWHIZ INC CHICAGO ILUS",                        None,       -10.23,     1787.39),
        ("01-20",  "POS W/D VENMO PAYMENT NEW YORK NYUS",                      None,       -50.00,     1737.39),
        ("01-21",  "POS W/D MCALISTERS 102435 NASHVILLE TNUS",                 None,       -28.75,     1708.64),
        ("01-26",  "POS W/D CHIPOTLE MEX GR ONLINE CAUS",                      None,       -13.45,     1695.19),
        ("01-26",  "POS W/D PAYPAL *MICROSOFT 402-935-7733 WAUS",              None,       -9.99,      1685.20),
        ("01-26",  "POS W/D TARGET T-1059 3171 LEBANON PIKE NASHVILLE TNUS",   None,       -88.42,     1596.78),
        ("01-28",  "Ext Deposit FAKE EMPLOYER INC 9999999999 - PAYROLL",        2800.00,    None,       4396.78),
        ("01-28",  "W/D Internet Transfer to 100000001 SAV",                   None,       -1200.00,   3196.78),
        ("01-29",  "POS W/D AMAZON.COM SEATTLE WAUS",                          None,       -34.99,     3161.79),
        ("01-29",  "POS W/D 7 BREW COFFEE SB925 MOUNT JULIET TNUS",            None,       -6.75,      3155.04),
        ("01-30",  "POS W/D ZAXBY'S #45501 HERMITAGE TNUS",                    None,       -17.43,     3137.61),
        ("01-30",  "Eff. 01-31 Credit Dividend",                                0.03,       None,       3137.64),
    ],
    "ytd_div": "0.03",
    "balance": "3,137.64",
    "div_rate": "0.050",
}

# ---------------------------------------------------------------------------
# PDF builder
# ---------------------------------------------------------------------------

class ECUStatement(FPDF):

    FONT = "Helvetica"
    PAGE_W = 216   # mm (8.5 in)
    PAGE_H = 279   # mm (11 in)
    MARGIN = 14

    def header(self):
        self.set_font(self.FONT, "B", 9)
        self.set_xy(self.MARGIN, 6)
        self.cell(0, 5, "Eastman Credit Union  |  P.O. Box 1989  |  Kingsport, TN 37662", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font(self.FONT, "", 8)
        self.set_x(self.MARGIN)
        self.cell(0, 4, f"Member Number: {MEMBER_NUMBER}    Statement Date: {STATEMENT_DATE}    Page {self.page_no()} of {{nb}}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(2)
        self.set_draw_color(180, 180, 180)
        self.line(self.MARGIN, self.get_y(), self.PAGE_W - self.MARGIN, self.get_y())
        self.ln(3)

    def footer(self):
        self.set_y(-12)
        self.set_font(self.FONT, "I", 7)
        self.set_text_color(120, 120, 120)
        self.cell(0, 5, "Want your statement earlier? View them online with e-statements! Sign-up today at www.ecu.org.", align="C")
        self.set_text_color(0, 0, 0)

    # ---- helpers ----

    def section_header(self, text: str):
        self.set_fill_color(220, 230, 242)
        self.set_font(self.FONT, "B", 9)
        self.set_x(self.MARGIN)
        self.cell(0, 6, f"  {text}", fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(1)

    def col_headers(self):
        self.set_font(self.FONT, "B", 7.5)
        self.set_x(self.MARGIN)
        cols = [("Trans\nDate", 16), ("Eff\nDate", 13), ("Description", 100), ("Deposit", 24), ("Withdrawal", 24), ("Balance", 25)]
        for label, w in cols:
            self.multi_cell(w, 3.5, label, align="L", new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.ln(8)
        self.set_draw_color(180, 180, 180)
        self.line(self.MARGIN, self.get_y(), self.PAGE_W - self.MARGIN, self.get_y())
        self.ln(1)

    def transaction_row(self, date, desc, deposit, withdrawal, balance):
        self.set_font(self.FONT, "", 7.5)
        self.set_x(self.MARGIN)
        row_y = self.get_y()

        dep_str  = f"{deposit:,.2f}"   if deposit    is not None else ""
        with_str = f"{withdrawal:,.2f}" if withdrawal is not None else ""
        bal_str  = f"{balance:,.2f}"

        # Negative sign for withdrawals
        if withdrawal is not None:
            with_str = f"-{abs(withdrawal):,.2f}"

        # Date col
        self.set_xy(self.MARGIN, row_y)
        self.cell(16, 4.5, date, new_x=XPos.RIGHT, new_y=YPos.TOP)
        # Eff date (blank)
        self.cell(13, 4.5, "", new_x=XPos.RIGHT, new_y=YPos.TOP)
        # Description (may wrap)
        x_before = self.get_x()
        self.multi_cell(100, 4.5, desc, new_x=XPos.RIGHT, new_y=YPos.TOP)
        new_y = self.get_y()
        # Deposit
        self.set_xy(x_before + 100, row_y)
        self.cell(24, 4.5, dep_str,  align="R", new_x=XPos.RIGHT, new_y=YPos.TOP)
        # Withdrawal
        self.cell(24, 4.5, with_str, align="R", new_x=XPos.RIGHT, new_y=YPos.TOP)
        # Balance
        self.cell(25, 4.5, bal_str,  align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(0.5)

    def account_section(self, acct: dict):
        self.section_header(f"{acct['name']}: {acct['number']}")
        self.col_headers()
        for row in acct["transactions"]:
            date, desc, dep, wdraw, bal = row
            if self.get_y() > self.PAGE_H - 30:
                self.add_page()
                self.section_header(f"{acct['name']}: {acct['number']} (Continued)")
                self.col_headers()
            self.transaction_row(date, desc, dep, wdraw, bal)
        self.ln(3)
        self.set_font(self.FONT, "", 7.5)
        self.set_x(self.MARGIN)
        self.cell(0, 4, f"The total number of days in this cycle: 31", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_x(self.MARGIN)
        self.cell(0, 4, f"The Annual Percentage Yield Earned for this account is {acct['div_rate']}%", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(5)

    def summary_section(self):
        self.section_header("SUMMARY OF ACCOUNTS")
        self.set_font(self.FONT, "B", 8)
        self.set_x(self.MARGIN)
        self.cell(90, 5, "ACCOUNTS", new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.cell(40, 5, "ACCOUNT NUMBER", new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.cell(30, 5, "BALANCE", align="R", new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.cell(20, 5, "YTD DIV", align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)

        self.set_font(self.FONT, "", 8)
        for acct in [SAVINGS_ACCOUNT, CHECKING_ACCOUNT]:
            self.set_x(self.MARGIN)
            self.cell(90, 5, acct["name"], new_x=XPos.RIGHT, new_y=YPos.TOP)
            self.cell(40, 5, acct["number"], new_x=XPos.RIGHT, new_y=YPos.TOP)
            self.cell(30, 5, acct["balance"], align="R", new_x=XPos.RIGHT, new_y=YPos.TOP)
            self.cell(20, 5, acct["ytd_div"], align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)

        self.ln(4)

    def address_block(self):
        self.set_font(self.FONT, "", 9)
        self.set_x(self.MARGIN)
        for line in MEMBER_NAME + ADDRESS:
            self.cell(0, 5, line, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(4)


# ---------------------------------------------------------------------------
# Generate
# ---------------------------------------------------------------------------

def generate(output_path: str = "fake_ecu_statement.pdf"):
    pdf = ECUStatement(orientation="P", unit="mm", format=(ECUStatement.PAGE_W, ECUStatement.PAGE_H))
    pdf.alias_nb_pages()
    pdf.set_auto_page_break(auto=True, margin=16)
    pdf.set_margins(ECUStatement.MARGIN, 18, ECUStatement.MARGIN)

    pdf.add_page()
    pdf.address_block()
    pdf.summary_section()

    pdf.section_header("DETAIL OF TRANSACTIONS")
    pdf.ln(2)

    pdf.account_section(SAVINGS_ACCOUNT)
    pdf.account_section(CHECKING_ACCOUNT)

    pdf.output(output_path)
    print(f"✅  Saved: {output_path}")


if __name__ == "__main__":
    import os
    out = os.path.join(os.path.dirname(__file__), "fake_ecu_statement.pdf")
    generate(out)
