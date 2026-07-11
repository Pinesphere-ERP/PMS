import asyncio, uuid
from decimal import Decimal
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from app.modules.payments.service import PaymentService
from app.modules.payments.schemas import PaymentCreate

async def main():
    engine = create_async_engine('postgresql+asyncpg://pinesphere_app:pinesphere_password@localhost:5444/pinesphere')
    async_session = async_sessionmaker(engine, expire_on_commit=False)
    async with async_session() as db:
        from sqlalchemy import text
        res = await db.execute(text('SELECT id FROM users LIMIT 1'))
        user_id = res.scalar()
        service = PaymentService(db)
        payment_data = PaymentCreate(payment_mode='online', amount=Decimal('100.00'))
        try:
            await service.create_payment(payment_data, user_id)
            await db.commit()
            print('success')
        except Exception as e:
            import traceback
            traceback.print_exc()

asyncio.run(main())