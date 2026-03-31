"""
Generates fake bank statement PDFs for testing BudgetCalc.

Supported banks:
  - ECU   (Eastman Credit Union) — existing format, two accounts
  - AMEX  (American Express)     — credit card statement
  - Chase (JPMorgan Chase)       — checking/savings statement

Usage:
  python3 generate_fake_statements.py           # generates all three
  python3 generate_fake_statements.py --bank ecu
  python3 generate_fake_statements.py --bank amex
  python3 generate_fake_statements.py --bank chase

Output: Scripts/ folder, e.g. fake_ecu_statement.pdf, fake_amex_statement.pdf, fake_chase_statement.pdf
"""

import os
import sys
import argparse
from fpdf import FPDF
from fpdf.enums import XPos, YPos

OUTPUT_DIR = os.path.dirname(__file__)

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

def fmt_amt(value: float, sign: bool = False) -> str:
    """Format a float as a dollar amount string."""
    if sign and value > 0:
        return f"+${value:,.2f}"
    return f"${abs(value):,.2f}"

# ---------------------------------------------------------------------------
# ECU — Eastman Credit Union
# ---------------------------------------------------------------------------

ECU_SAVINGS = {
    "name": "Primary Share Account",
    "number": "XXXXXXX00001",
    "starting_balance": 4200.00,
    "balance": "6,109.80",
    "ytd_div": "9.80",
    "div_rate": "0.300",
    "transactions": [
        ("01-01", "Starting Balance",                               None,     None,      4200.00),
        ("01-05", "W/D Internet Transfer to 100000002 CK",          None,     -500.00,   3700.00),
        ("01-14", "Deposit Internet Transfer from 100000002 CK",    1200.00,  None,      4900.00),
        ("01-26", "Extraordinary Dividend Extraordinary Dividend",   8.75,    None,      4908.75),
        ("01-28", "Deposit Internet Transfer from 100000002 CK",    1200.00,  None,      6108.75),
        ("01-30", "Eff. 01-31 Credit Dividend",                     1.05,    None,      6109.80),
    ],
}

ECU_CHECKING = {
    "name": "Beyond Free Checking Account",
    "number": "XXXXXXX00002",
    "starting_balance": 980.00,
    "balance": "3,137.64",
    "ytd_div": "0.03",
    "div_rate": "0.050",
    "transactions": [
        ("01-01", "Starting Balance",                                          None,     None,      980.00),
        ("01-02", "POS W/D WAL-MART #0710 4424 LEBANON PIKE HERMITAGE TNUS",  None,     -62.14,    917.86),
        ("01-02", "POS W/D ZAXBY'S #45501 HERMITAGE TNUS",                    None,     -11.37,    906.49),
        ("01-02", "Ext Deposit VENMO - CASHOUT",                               40.00,    None,      946.49),
        ("01-05", "POS W/D CHICK-FIL-A #01764 HERMITAGE TNUS",                None,     -18.45,    928.04),
        ("01-05", "POS W/D TST* JACK BROWN'S JOINT NASHVILLE TNUS",           None,     -44.07,    883.97),
        ("01-05", "POS W/D KILWINS 0134 FRANKLIN TNUS",                       None,     -31.50,    852.47),
        ("01-05", "Deposit Internet Transfer from 100000001 SAV",              500.00,   None,     1352.47),
        ("01-05", "POS W/D NASHVILLE MLS SOCCER 615-000-0000 TNUS",           None,     -44.00,   1308.47),
        ("01-06", "POS W/D APPLE.COM/BILL 866-712-7753 CAUS",                 None,     -0.99,    1307.48),
        ("01-07", "POS W/D WALMART.COM 8009256 702 SW 8TH ST BENTONVILLE AR", None,     -54.22,   1253.26),
        ("01-08", "POS W/D APPLE.COM/BILL 866-712-7753 CAUS",                 None,     -16.99,   1236.27),
        ("01-12", "POS W/D CHICK-FIL-A #01764 615-889-2177 TNUS",             None,     -28.50,   1207.77),
        ("01-12", "POS W/D LA HACIENDA MEXICAN RES NASHVILLE TNUS",           None,     -39.80,   1167.97),
        ("01-12", "Ext W/D TARGET CARD SRVC - PAYMENT",                       None,     -150.00,  1017.97),
        ("01-14", "Ext Deposit FAKE EMPLOYER INC 9999999999 - PAYROLL",       2800.00,  None,     3817.97),
        ("01-14", "W/D Internet Transfer to 100000001 SAV",                   None,    -1200.00,  2617.97),
        ("01-15", "Ext W/D AMERICANEXPRESS PERSONAL SAVINGS - TRANSFER",      None,     -600.00,  2017.97),
        ("01-16", "POS W/D MCDONALD'S F7397 545 DONELSON PIKE NASHVILLE TN",  None,     -14.22,   2003.75),
        ("01-16", "POS W/D NES ELECTRIC BILLPAY - BILLPAY",                   None,     -122.00,  1881.75),
        ("01-20", "POS W/D CHICK-FIL-A APP 866-232-2040 GAUS",                None,     -10.00,   1871.75),
        ("01-20", "POS W/D WM SUPERCENTER #710 4424 LEBANON PIKE TN",         None,     -74.13,   1797.62),
        ("01-20", "POS W/D PARKWHIZ INC CHICAGO ILUS",                        None,     -10.23,   1787.39),
        ("01-20", "POS W/D VENMO PAYMENT NEW YORK NYUS",                      None,     -50.00,   1737.39),
        ("01-21", "POS W/D MCALISTERS 102435 NASHVILLE TNUS",                 None,     -28.75,   1708.64),
        ("01-26", "POS W/D CHIPOTLE MEX GR ONLINE CAUS",                      None,     -13.45,   1695.19),
        ("01-26", "POS W/D PAYPAL *MICROSOFT 402-935-7733 WAUS",              None,     -9.99,    1685.20),
        ("01-26", "POS W/D TARGET T-1059 3171 LEBANON PIKE NASHVILLE TNUS",   None,     -88.42,   1596.78),
        ("01-28", "Ext Deposit FAKE EMPLOYER INC 9999999999 - PAYROLL",       2800.00,  None,     4396.78),
        ("01-28", "W/D Internet Transfer to 100000001 SAV",                   None,    -1200.00,  3196.78),
        ("01-29", "POS W/D AMAZON.COM SEATTLE WAUS",                          None,     -34.99,   3161.79),
        ("01-29", "POS W/D 7 BREW COFFEE SB925 MOUNT JULIET TNUS",            None,     -6.75,    3155.04),
        ("01-30", "POS W/D ZAXBY'S #45501 HERMITAGE TNUS",                    None,     -17.43,   3137.61),
        ("01-30", "Eff. 01-31 Credit Dividend",                                0.03,    None,     3137.64),
    ],
}

class ECUStatement(FPDF):
    FONT  = "Helvetica"
    PAGE_W = 216
    PAGE_H = 279
    MARGIN = 14

    def header(self):
        self.set_font(self.FONT, "B", 9)
        self.set_xy(self.MARGIN, 6)
        self.cell(0, 5, "Eastman Credit Union  |  P.O. Box 1989  |  Kingsport, TN 37662",
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font(self.FONT, "", 8)
        self.set_x(self.MARGIN)
        self.cell(0, 4,
                  f"Member Number: 00000000    Statement Date: 01/31/26    Page {self.page_no()} of {{nb}}",
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(2)
        self.set_draw_color(180, 180, 180)
        self.line(self.MARGIN, self.get_y(), self.PAGE_W - self.MARGIN, self.get_y())
        self.ln(3)

    def footer(self):
        self.set_y(-12)
        self.set_font(self.FONT, "I", 7)
        self.set_text_color(120, 120, 120)
        self.cell(0, 5, "Want your statement earlier? View them online with e-statements! Sign-up today at www.ecu.org.",
                  align="C")
        self.set_text_color(0, 0, 0)

    def section_header(self, text):
        self.set_fill_color(220, 230, 242)
        self.set_font(self.FONT, "B", 9)
        self.set_x(self.MARGIN)
        self.cell(0, 6, f"  {text}", fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(1)

    def col_headers(self):
        self.set_font(self.FONT, "B", 7.5)
        self.set_x(self.MARGIN)
        cols = [("Trans\nDate", 16), ("Eff\nDate", 13), ("Description", 100),
                ("Deposit", 24), ("Withdrawal", 24), ("Balance", 25)]
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
        dep_str  = f"{deposit:,.2f}"            if deposit    is not None else ""
        with_str = f"-{abs(withdrawal):,.2f}"   if withdrawal is not None else ""
        bal_str  = f"{balance:,.2f}"
        self.set_xy(self.MARGIN, row_y);  self.cell(16, 4.5, date, new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.cell(13, 4.5, "", new_x=XPos.RIGHT, new_y=YPos.TOP)
        x_before = self.get_x()
        self.multi_cell(100, 4.5, desc, new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.set_xy(x_before + 100, row_y)
        self.cell(24, 4.5, dep_str,  align="R", new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.cell(24, 4.5, with_str, align="R", new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.cell(25, 4.5, bal_str,  align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(0.5)

    def account_section(self, acct):
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
        self.set_font(self.FONT, "", 7.5);  self.set_x(self.MARGIN)
        self.cell(0, 4, f"The Annual Percentage Yield Earned for this account is {acct['div_rate']}%",
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(5)

    def summary_section(self):
        self.section_header("SUMMARY OF ACCOUNTS")
        self.set_font(self.FONT, "B", 8);  self.set_x(self.MARGIN)
        self.cell(90, 5, "ACCOUNTS",       new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.cell(40, 5, "ACCOUNT NUMBER", new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.cell(30, 5, "BALANCE",   align="R", new_x=XPos.RIGHT,  new_y=YPos.TOP)
        self.cell(20, 5, "YTD DIV",   align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font(self.FONT, "", 8)
        for acct in [ECU_SAVINGS, ECU_CHECKING]:
            self.set_x(self.MARGIN)
            self.cell(90, 5, acct["name"],   new_x=XPos.RIGHT, new_y=YPos.TOP)
            self.cell(40, 5, acct["number"], new_x=XPos.RIGHT, new_y=YPos.TOP)
            self.cell(30, 5, acct["balance"],   align="R", new_x=XPos.RIGHT,  new_y=YPos.TOP)
            self.cell(20, 5, acct["ytd_div"],   align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(4)

def generate_ecu(output_path):
    pdf = ECUStatement(orientation="P", unit="mm", format=(ECUStatement.PAGE_W, ECUStatement.PAGE_H))
    pdf.alias_nb_pages()
    pdf.set_auto_page_break(auto=True, margin=16)
    pdf.set_margins(ECUStatement.MARGIN, 18, ECUStatement.MARGIN)
    pdf.add_page()
    pdf.set_font("Helvetica", "", 9)
    pdf.set_x(ECUStatement.MARGIN)
    for line in ["JOHN A TESTUSER", "JANE B TESTUSER", "123 FAKE STREET", "ANYTOWN TN 00000-0000"]:
        pdf.cell(0, 5, line, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(4)
    pdf.summary_section()
    pdf.section_header("DETAIL OF TRANSACTIONS");  pdf.ln(2)
    pdf.account_section(ECU_SAVINGS)
    pdf.account_section(ECU_CHECKING)
    pdf.output(output_path)
    print(f"✅  ECU   → {output_path}")

# ---------------------------------------------------------------------------
# AMEX — American Express Credit Card
# ---------------------------------------------------------------------------

AMEX_TRANSACTIONS = [
    # (date MM/DD/YY, description, amount)  — positive = charge, negative = payment/credit
    ("01/02/26", "WHOLE FOODS MARKET #10452 NASHVILLE TN",          -87.43),
    ("01/03/26", "NETFLIX.COM",                                      -15.99),
    ("01/04/26", "UBER* TRIP HELP.UBER.COM CA",                      -14.25),
    ("01/05/26", "CHICK-FIL-A #01764 HERMITAGE TN",                  -11.87),
    ("01/06/26", "AMAZON.COM*2X4TY9PQ0 AMZN.COM/BILL WA",           -34.99),
    ("01/07/26", "SHELL OIL 57444842400 NASHVILLE TN",               -52.10),
    ("01/08/26", "TARGET 00012595 HERMITAGE TN",                     -64.22),
    ("01/10/26", "SPOTIFY USA",                                       -9.99),
    ("01/10/26", "PAYMENT - THANK YOU",                             -350.00),   # credit
    ("01/11/26", "CHEESECAKE FACTORY #0322 NASHVILLE TN",            -68.45),
    ("01/12/26", "COSTCO WHSE #0473 ANTIOCH TN",                    -143.67),
    ("01/13/26", "UBER EATS PENDING",                                -22.50),
    ("01/14/26", "CVS/PHARMACY #4802 HERMITAGE TN",                  -18.32),
    ("01/15/26", "DELTA AIR 0062319485325 DELTA.COM GA",            -289.00),
    ("01/16/26", "MCDONALD'S F7397 NASHVILLE TN",                    -12.43),
    ("01/17/26", "APPLE.COM/BILL",                                    -2.99),
    ("01/18/26", "HOME DEPOT #6908 HERMITAGE TN",                    -74.18),
    ("01/19/26", "WALGREENS #4501 HERMITAGE TN",                     -23.55),
    ("01-20-26", "ZAXBY'S #45501 HERMITAGE TN",                      -16.87),
    ("01/21/26", "AMAZON WEB SERVICES AWS.AMAZON.CO WA",             -12.00),
    ("01/22/26", "PUBLIX #1234 NASHVILLE TN",                        -91.30),
    ("01/23/26", "LYFT *RIDE SUN 5PM LYFT.COM CA",                   -18.75),
    ("01/25/26", "BEST BUY 00003137 NASHVILLE TN",                  -129.99),
    ("01/26/26", "CHIPOTLE 3728 HERMITAGE TN",                       -13.87),
    ("01/27/26", "HULU",                                             -17.99),
    ("01/28/26", "PLANET FITNESS #935 HERMITAGE TN",                 -24.99),
    ("01/29/26", "PANERA BREAD #204341 NASHVILLE TN",                -16.55),
    ("01/30/26", "STARBUCKS STORE 12345 NASHVILLE TN",                -8.45),
]

AMEX_PREV_BALANCE  =  487.33
AMEX_PAYMENTS      =  350.00
AMEX_NEW_CHARGES   = sum(a for _, _, a in AMEX_TRANSACTIONS if a > 0)
AMEX_NEW_BALANCE   = AMEX_PREV_BALANCE - AMEX_PAYMENTS + sum(abs(a) for _, _, a in AMEX_TRANSACTIONS if a > 0)
AMEX_MIN_PAYMENT   = max(35.00, AMEX_NEW_BALANCE * 0.02)
AMEX_CREDIT_LIMIT  = 10000.00

class AMEXStatement(FPDF):
    FONT   = "Helvetica"
    PAGE_W = 216
    PAGE_H = 279
    MARGIN = 16

    def header(self):
        # Blue AMEX header bar
        self.set_fill_color(0, 114, 187)
        self.rect(0, 0, self.PAGE_W, 20, "F")
        self.set_font(self.FONT, "B", 13)
        self.set_text_color(255, 255, 255)
        self.set_xy(self.MARGIN, 6)
        self.cell(80, 8, "American Express", new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.set_font(self.FONT, "", 8)
        self.set_xy(self.PAGE_W - self.MARGIN - 80, 5)
        self.cell(80, 5, "Account Ending 10005", align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_xy(self.PAGE_W - self.MARGIN - 80, 10)
        self.cell(80, 5, "Closing Date: 01/31/26", align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(0, 0, 0)
        self.ln(6)

    def footer(self):
        self.set_y(-12)
        self.set_font(self.FONT, "I", 7)
        self.set_text_color(120, 120, 120)
        self.cell(0, 5, f"Page {self.page_no()} - americanexpress.com", align="C")
        self.set_text_color(0, 0, 0)

    def account_summary(self):
        self.set_font(self.FONT, "B", 10)
        self.set_x(self.MARGIN)
        self.cell(0, 6, "Account Summary", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_draw_color(0, 114, 187)
        self.line(self.MARGIN, self.get_y(), self.PAGE_W - self.MARGIN, self.get_y())
        self.ln(3)

        rows = [
            ("Previous Balance",    f"${AMEX_PREV_BALANCE:,.2f}"),
            ("Payments & Credits",  f"-${AMEX_PAYMENTS:,.2f}"),
            ("New Charges",         f"${sum(abs(a) for _,_,a in AMEX_TRANSACTIONS if a > 0):,.2f}"),
            ("New Balance",         f"${AMEX_NEW_BALANCE:,.2f}"),
            ("Minimum Payment Due", f"${AMEX_MIN_PAYMENT:,.2f}"),
            ("Credit Limit",        f"${AMEX_CREDIT_LIMIT:,.2f}"),
            ("Payment Due Date",    "02/28/26"),
        ]
        self.set_font(self.FONT, "", 8.5)
        for label, value in rows:
            self.set_x(self.MARGIN)
            self.cell(100, 5, label, new_x=XPos.RIGHT, new_y=YPos.TOP)
            self.cell(80,  5, value, align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(5)

    def transactions_section(self):
        self.set_font(self.FONT, "B", 10)
        self.set_x(self.MARGIN)
        self.cell(0, 6, "New Activity", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_draw_color(0, 114, 187)
        self.line(self.MARGIN, self.get_y(), self.PAGE_W - self.MARGIN, self.get_y())
        self.ln(2)

        # Column headers
        self.set_fill_color(240, 240, 240)
        self.set_font(self.FONT, "B", 8)
        self.set_x(self.MARGIN)
        self.cell(25,  5, "Date",        fill=True, new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.cell(135, 5, "Description", fill=True, new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.cell(26,  5, "Amount",      fill=True, align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(1)

        self.set_font(self.FONT, "", 8)
        for date, desc, amount in AMEX_TRANSACTIONS:
            if self.get_y() > self.PAGE_H - 25:
                self.add_page()
                self.set_font(self.FONT, "B", 8)
                self.set_x(self.MARGIN)
                self.cell(25, 5, "Date",        new_x=XPos.RIGHT, new_y=YPos.TOP)
                self.cell(135, 5, "Description", new_x=XPos.RIGHT, new_y=YPos.TOP)
                self.cell(26, 5, "Amount", align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
                self.set_font(self.FONT, "", 8)

            amt_str = f"${abs(amount):,.2f}"
            if amount < 0:
                amt_str = f"-${abs(amount):,.2f}"   # payment / credit

            row_y = self.get_y()
            self.set_x(self.MARGIN)
            self.cell(25, 4.5, date, new_x=XPos.RIGHT, new_y=YPos.TOP)
            x_desc = self.get_x()
            self.multi_cell(135, 4.5, desc, new_x=XPos.RIGHT, new_y=YPos.TOP)
            self.set_xy(x_desc + 135, row_y)
            color = (0, 150, 0) if amount < 0 else (0, 0, 0)
            self.set_text_color(*color)
            self.cell(26, 4.5, amt_str, align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
            self.set_text_color(0, 0, 0)
            self.ln(0.5)

def generate_amex(output_path):
    pdf = AMEXStatement(orientation="P", unit="mm", format=(AMEXStatement.PAGE_W, AMEXStatement.PAGE_H))
    pdf.alias_nb_pages()
    pdf.set_auto_page_break(auto=True, margin=16)
    pdf.set_margins(AMEXStatement.MARGIN, 22, AMEXStatement.MARGIN)
    pdf.add_page()
    # Cardholder info
    pdf.set_font("Helvetica", "", 9)
    pdf.set_x(AMEXStatement.MARGIN)
    for line in ["JOHN A TESTUSER", "123 FAKE STREET", "ANYTOWN TN 00000"]:
        pdf.cell(0, 5, line, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(4)
    pdf.account_summary()
    pdf.transactions_section()
    pdf.output(output_path)
    print(f"✅  AMEX  → {output_path}")

# ---------------------------------------------------------------------------
# Chase — JPMorgan Chase Bank
# ---------------------------------------------------------------------------

CHASE_TRANSACTIONS = [
    # (date MM/DD, description, amount, balance)
    # positive = deposit, negative = withdrawal
    ("01/01", "Beginning Balance",                                    None,        2_450.00),
    ("01/02", "ACH CREDIT EMPLOYER INC DIR DEP",                   3_100.00,      5_550.00),
    ("01/02", "PURCHASE WHOLEFDS #10452 NASHVILLE TN",               -91.22,      5_458.78),
    ("01/03", "PURCHASE AMAZON.COM*AB1CD2 AMZN.COM/BILL WA",        -47.99,       5_410.79),
    ("01/04", "ATM WITHDRAWAL CHASE ATM 1234 NASHVILLE",            -100.00,      5_310.79),
    ("01/05", "PURCHASE SHELL SERVICE 57444 NASHVILLE TN",           -55.40,      5_255.39),
    ("01/06", "PURCHASE CHICK-FIL-A #01764 HERMITAGE TN",            -13.87,      5_241.52),
    ("01/07", "ONLINE TRANSFER TO CHASE SAVINGS (...0002)",         -500.00,      4_741.52),
    ("01/08", "PURCHASE TARGET 00012595 HERMITAGE TN",               -78.34,      4_663.18),
    ("01/09", "PURCHASE NETFLIX.COM 866-579-7172 CA",                -15.99,      4_647.19),
    ("01/10", "PURCHASE ZAXBY'S #45501 HERMITAGE TN",                -14.22,      4_632.97),
    ("01/11", "PURCHASE KROGER #0419 NASHVILLE TN",                  -62.88,      4_570.09),
    ("01/12", "PURCHASE LYFT *RIDE HELP.LYFT.COM CA",                -22.50,      4_547.59),
    ("01/13", "PURCHASE WALGREENS #4501 HERMITAGE TN",               -31.17,      4_516.42),
    ("01/14", "PURCHASE HOME DEPOT #6908 HERMITAGE TN",              -88.45,      4_427.97),
    ("01/15", "PURCHASE CHIPOTLE 3728 HERMITAGE TN",                 -12.87,      4_415.10),
    ("01/16", "ACH DEBIT AMEX AUTOPAY",                             -412.00,      4_003.10),
    ("01/17", "PURCHASE STARBUCKS STORE 12345 NASHVILLE TN",         -11.25,      3_991.85),
    ("01/18", "ZELLE PAYMENT TO FRIEND",                             -75.00,      3_916.85),
    ("01/20", "PURCHASE MCDONALD'S F7397 NASHVILLE TN",              -10.43,      3_906.42),
    ("01/21", "PURCHASE COSTCO WHSE #0473 ANTIOCH TN",              -167.22,      3_739.20),
    ("01/22", "PURCHASE PLANET FITNESS #935 HERMITAGE TN",           -24.99,      3_714.21),
    ("01/23", "PURCHASE APPLE.COM/BILL 866-712-7753 CA",              -2.99,      3_711.22),
    ("01/24", "PURCHASE PANERA BREAD #204341 NASHVILLE TN",          -19.45,      3_691.77),
    ("01/25", "PURCHASE BEST BUY 00003137 NASHVILLE TN",             -54.99,      3_636.78),
    ("01/26", "PURCHASE PUBLIX #1234 NASHVILLE TN",                  -88.12,      3_548.66),
    ("01/27", "ZELLE PAYMENT FROM ROOMMATE",                        +200.00,      3_748.66),
    ("01/28", "ACH CREDIT EMPLOYER INC DIR DEP",                   3_100.00,      6_848.66),
    ("01/28", "ONLINE TRANSFER TO CHASE SAVINGS (...0002)",         -500.00,      6_348.66),
    ("01/29", "PURCHASE AMAZON.COM SEATTLE WA",                      -29.99,      6_318.67),
    ("01/30", "PURCHASE UBER* TRIP HELP.UBER.COM CA",                -16.75,      6_301.92),
    ("01/31", "INTEREST PAYMENT",                                      +0.53,     6_302.45),
]

class ChaseStatement(FPDF):
    FONT   = "Helvetica"
    PAGE_W = 216
    PAGE_H = 279
    MARGIN = 16

    def header(self):
        self.set_fill_color(0, 80, 160)
        self.rect(0, 0, self.PAGE_W, 18, "F")
        self.set_font(self.FONT, "B", 12)
        self.set_text_color(255, 255, 255)
        self.set_xy(self.MARGIN, 5)
        self.cell(60, 8, "CHASE", new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.set_font(self.FONT, "", 8)
        self.set_xy(self.PAGE_W - self.MARGIN - 80, 4)
        self.cell(80, 4, "Account: ...0001  |  Statement Period: 01/01/26 - 01/31/26", align="R",
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_xy(self.PAGE_W - self.MARGIN - 80, 9)
        self.cell(80, 4, f"Page {self.page_no()}", align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(0, 0, 0)
        self.ln(5)

    def footer(self):
        self.set_y(-12)
        self.set_font(self.FONT, "I", 7)
        self.set_text_color(120, 120, 120)
        self.cell(0, 5, "chase.com  |  1-800-935-9935", align="C")
        self.set_text_color(0, 0, 0)

    def account_summary(self):
        self.set_font(self.FONT, "B", 10)
        self.set_x(self.MARGIN)
        self.cell(0, 6, "Account Summary - Chase Total Checking ...0001",
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_draw_color(0, 80, 160)
        self.line(self.MARGIN, self.get_y(), self.PAGE_W - self.MARGIN, self.get_y())
        self.ln(3)

        deposits = sum(a for _, _, a, _ in CHASE_TRANSACTIONS if a is not None and a > 0)
        withdrawals = sum(abs(a) for _, _, a, _ in CHASE_TRANSACTIONS if a is not None and a < 0)
        rows = [
            ("Beginning Balance",   "$2,450.00"),
            ("Total Deposits",      f"${deposits:,.2f}"),
            ("Total Withdrawals",   f"${withdrawals:,.2f}"),
            ("Ending Balance",      f"${CHASE_TRANSACTIONS[-1][3]:,.2f}"),
        ]
        self.set_font(self.FONT, "", 8.5)
        for label, value in rows:
            self.set_x(self.MARGIN)
            self.cell(100, 5, label, new_x=XPos.RIGHT, new_y=YPos.TOP)
            self.cell(80,  5, value, align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(5)

    def transactions_section(self):
        self.set_font(self.FONT, "B", 10)
        self.set_x(self.MARGIN)
        self.cell(0, 6, "Transaction Detail", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_draw_color(0, 80, 160)
        self.line(self.MARGIN, self.get_y(), self.PAGE_W - self.MARGIN, self.get_y())
        self.ln(2)

        # Column headers
        self.set_fill_color(240, 240, 240)
        self.set_font(self.FONT, "B", 8)
        self.set_x(self.MARGIN)
        self.cell(20,  5, "Date",        fill=True, new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.cell(115, 5, "Description", fill=True, new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.cell(27,  5, "Amount",      fill=True, align="R", new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.cell(24,  5, "Balance",     fill=True, align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(1)

        self.set_font(self.FONT, "", 8)
        for date, desc, amount, balance in CHASE_TRANSACTIONS:
            if self.get_y() > self.PAGE_H - 25:
                self.add_page()

            amt_str = ""
            if amount is not None:
                amt_str = f"+${amount:,.2f}" if amount > 0 else f"-${abs(amount):,.2f}"

            row_y = self.get_y()
            self.set_x(self.MARGIN)
            self.cell(20, 4.5, date, new_x=XPos.RIGHT, new_y=YPos.TOP)
            x_desc = self.get_x()
            self.multi_cell(115, 4.5, desc, new_x=XPos.RIGHT, new_y=YPos.TOP)
            self.set_xy(x_desc + 115, row_y)
            if amount is not None and amount > 0:
                self.set_text_color(0, 140, 0)
            self.cell(27, 4.5, amt_str, align="R", new_x=XPos.RIGHT, new_y=YPos.TOP)
            self.set_text_color(0, 0, 0)
            self.cell(24, 4.5, f"${balance:,.2f}", align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
            self.ln(0.5)

def generate_chase(output_path):
    pdf = ChaseStatement(orientation="P", unit="mm", format=(ChaseStatement.PAGE_W, ChaseStatement.PAGE_H))
    pdf.alias_nb_pages()
    pdf.set_auto_page_break(auto=True, margin=16)
    pdf.set_margins(ChaseStatement.MARGIN, 22, ChaseStatement.MARGIN)
    pdf.add_page()
    pdf.set_font("Helvetica", "", 9)
    pdf.set_x(ChaseStatement.MARGIN)
    for line in ["JOHN A TESTUSER", "123 FAKE STREET", "ANYTOWN TN 00000"]:
        pdf.cell(0, 5, line, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(4)
    pdf.account_summary()
    pdf.transactions_section()
    pdf.output(output_path)
    print(f"✅  Chase → {output_path}")

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

GENERATORS = {
    "ecu":   (generate_ecu,   "fake_ecu_statement.pdf"),
    "amex":  (generate_amex,  "fake_amex_statement.pdf"),
    "chase": (generate_chase, "fake_chase_statement.pdf"),
}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate fake bank statement PDFs for BudgetCalc testing.")
    parser.add_argument("--bank", choices=["ecu", "amex", "chase"],
                        help="Which bank to generate. Omit to generate all three.")
    args = parser.parse_args()

    banks = [args.bank] if args.bank else list(GENERATORS.keys())
    for bank in banks:
        fn, filename = GENERATORS[bank]
        fn(os.path.join(OUTPUT_DIR, filename))
