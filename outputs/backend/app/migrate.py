"""Apply supported additive schema revisions without recreating existing tables."""

from sqlalchemy import select

from .config import Settings
from .db import SchemaRevision, database, transaction


def main():
    engine, factory = database(Settings().database_url)
    try:
        with transaction(factory) as session:
            print(
                "Applied schema revisions:", session.scalars(select(SchemaRevision.version)).all()
            )
    finally:
        engine.dispose()


if __name__ == "__main__":
    main()
