"""
Lab 5 ORM - SQLAlchemy 2.0 examples
Diminta: mendemonstrasikan N+1 problem dan solusinya dengan eager loading.
Dipilih: SQLAlchemy 2.0 dengan declarative base dan selectinload/joinedload.
Alternatif: raw SQL saja; tidak dipilih karena diminta perbandingan ORM vs SQL.
"""

import os
from sqlalchemy import create_engine, select, func, text, ForeignKey
from sqlalchemy.orm import (
    DeclarativeBase, Mapped, mapped_column, relationship, Session,
    selectinload, joinedload
)

# Gunakan postgresql+psycopg:// agar SQLAlchemy pakai psycopg 3
DSN = os.environ.get("DSN", "postgresql+psycopg://msbd:msbd2026@localhost:5432/pagila")
engine = create_engine(DSN, echo=True)


# ============================================================
# Q16: Model Deklaratif
# ============================================================
class Base(DeclarativeBase):
    pass


class Customer(Base):
    __tablename__ = "customer"
    __table_args__ = {"schema": "public"}
    
    customer_id: Mapped[int] = mapped_column(primary_key=True)
    first_name: Mapped[str] = mapped_column()
    last_name: Mapped[str] = mapped_column()
    email: Mapped[str] = mapped_column()
    
    # Relasi ke RentalTx
    rentals = relationship("RentalTx", back_populates="customer")


class RentalTx(Base):
    __tablename__ = "rental_tx"
    __table_args__ = {"schema": "lab5"}
    
    rental_id: Mapped[int] = mapped_column(primary_key=True)
    
    # PERBAIKAN UTAMA: Tambahkan ForeignKey eksplisit dengan nama skema
    customer_id: Mapped[int] = mapped_column(ForeignKey("public.customer.customer_id"))
    
    inventory_id: Mapped[int] = mapped_column()
    staff_id: Mapped[int] = mapped_column()
    status: Mapped[str] = mapped_column()
    
    # Relasi ke Customer
    customer = relationship("Customer", back_populates="rentals")


# ============================================================
# Q17: Bukti N+1
# ============================================================
def q17_bukti_n_plus_1():
    print("\n=== Q17: Bukti N+1 ===")
    print("Ambil 10 customer, akses rentals masing-masing")
    print("Target: 11 SELECT (1 untuk customer + 10 untuk rentals)")
    
    with Session(engine) as session:
        customers = session.scalars(select(Customer).limit(10)).all()
        print(f"\nJumlah customer: {len(customers)}")
        
        # Akses relasi rentals untuk setiap customer -> memicu N+1
        for c in customers:
            print(f"Customer {c.customer_id}: {len(c.rentals)} rentals")


# ============================================================
# Q18: selectinload
# ============================================================
def q18_selectinload():
    print("\n=== Q18: selectinload ===")
    print("Target: 2 SELECT (1 untuk customer + 1 untuk semua rentals)")
    
    with Session(engine) as session:
        customers = session.scalars(
            select(Customer)
            .options(selectinload(Customer.rentals))
            .limit(10)
        ).all()
        
        for c in customers:
            print(f"Customer {c.customer_id}: {len(c.rentals)} rentals")


# ============================================================
# Q19: joinedload
# ============================================================
def q19_joinedload():
    print("\n=== Q19: joinedload ===")
    print("Target: 1 SELECT dengan JOIN")
    
    with Session(engine) as session:
        customers = session.scalars(
            select(Customer)
            .options(joinedload(Customer.rentals))
            .limit(10)
        ).unique().all()  # PERBAIKAN: Tambahkan .unique() sebelum .all()
        
        for c in customers:
            print(f"Customer {c.customer_id}: {len(c.rentals)} rentals")

# ============================================================
# Q20: ORM vs SQL Mentah
# ============================================================
def q20_orm_vs_sql():
    print("\n=== Q20: ORM vs SQL Mentah ===")
    
    # Versi ORM
    print("\n[Versi ORM]")
    with Session(engine) as session:
        result = session.execute(
            select(Customer.customer_id, func.count(RentalTx.rental_id).label("rental_count"))
            .join(RentalTx, Customer.customer_id == RentalTx.customer_id)
            .group_by(Customer.customer_id)
            .order_by(func.count(RentalTx.rental_id).desc())
            .limit(5)
        )
        for row in result:
            print(f"  Customer {row.customer_id}: {row.rental_count} rentals")
    
    # Versi SQL mentah
    print("\n[Versi SQL Mentah]")
    with engine.connect() as conn:
        result = conn.execute(text("""
            SELECT c.customer_id, count(r.rental_id) AS rental_count
            FROM public.customer c
            JOIN lab5.rental_tx r ON c.customer_id = r.customer_id
            GROUP BY c.customer_id
            ORDER BY rental_count DESC
            LIMIT 5
        """))
        for row in result:
            print(f"  Customer {row[0]}: {row[1]} rentals")


# ============================================================
# Main
# ============================================================
if __name__ == "__main__":
    print("=== Memulai Lab 5 ORM (SQLAlchemy 2.0) ===")
    q17_bukti_n_plus_1()
    q18_selectinload()
    q19_joinedload()
    q20_orm_vs_sql()
    print("\n=== Semua Q17-Q20 selesai ===")