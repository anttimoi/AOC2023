import glob
from dotenv import dotenv_values

from natsort import os_sorted
import psycopg2
from psycopg2 import sql
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from psycopg2.errors import DuplicateDatabase


class Database:
    def __init__(
        self,
        *,
        host: str,
        username: str,
        password: str,
        database_name: str,
    ):
        self.host: str = host
        self.username: str = username
        self.password: str = password
        self.database_name: str = database_name

        self._initialized: bool = False
        self._connection = None

    def create_database(self):
        connection = psycopg2.connect(
            dbname='postgres',
            user=self.username,
            host=self.host,
            password=self.password
        )

        connection.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)

        cursor = connection.cursor()

        try:
            cursor.execute(sql.SQL("CREATE DATABASE {}").format(
                sql.Identifier(self.database_name))
            )
        except DuplicateDatabase:
            cursor.execute(sql.SQL("DROP DATABASE {}").format(
                sql.Identifier(self.database_name))
            )
            self.create_database()

        self._connection = psycopg2.connect(
            dbname=self.database_name,
            user=self.username,
            host=self.host,
            password=self.password
        )

        self._initialized = True

    def execute_sql(self, sql: str, output_file: str = None):
        self._validate_initialization()
        with self._connection.cursor() as cursor:
            cursor.execute(sql)
            if output_file:
                with open(output_file, 'w') as f:
                    f.write(str(cursor.fetchall()))
            else:
                print(cursor.fetchall())

    def _validate_initialization(self):
        if not self._initialized:
            raise Exception('Database not initialized')


if __name__ == '__main__':
    config = dotenv_values(".env")

    db = Database(
        username=config.get('USERNAME'),
        password=config.get('PASSWORD'),
        database_name=config.get('DATABASE_NAME'),
        host=config.get('HOST'),
    )
    db.create_database()

    files = glob.glob('*.sql')
    files = os_sorted(files)

    for file in files:
        print(file)
        with open(file, 'r') as f:
            db.execute_sql(f.read(), output_file=f'{file}.out')
