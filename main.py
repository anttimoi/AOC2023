import glob
import os
from dotenv import dotenv_values
from pathlib import Path

from natsort import os_sorted
import psycopg2
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
            cursor.execute(f"CREATE DATABASE {self.database_name}")
        except DuplicateDatabase:
            cursor.execute(f"DROP DATABASE {self.database_name}")
            self.create_database()

        self._connection = psycopg2.connect(
            dbname=self.database_name,
            user=self.username,
            host=self.host,
            password=self.password
        )

        self._initialized = True

    def execute_sql(self, sql: str):
        self._validate_initialization()
        with self._connection.cursor() as cursor:
            cursor.execute(sql)

    def execute_sql_with_result(self, sql: str) -> str:
        self._validate_initialization()
        with self._connection.cursor() as cursor:
            cursor.execute(sql)
            return str(cursor.fetchone()[0])

    def _validate_initialization(self):
        if not self._initialized:
            raise Exception('Database not initialized')


class Assignment:
    def __init__(self, assignment_id: str, database: Database):
        self._assignment_id = assignment_id
        self._database = database
        self._table_name = f'assignment_{assignment_id}'

        directory = 'assignments'
        self._txt_file = os.path.join(directory, f'{assignment_id}.txt')
        self._sql_file = os.path.join(directory, f'{assignment_id}.sql')
        self._out_file = os.path.join(directory, f'{assignment_id}.out')

    def load_puzzle_input(self):
        self._create_puzzle_input_table()

        with open(self._txt_file, 'r') as f:
            input_rows = f.read().splitlines()
            self._insert_puzzle_input(input_rows)

    def execute_puzzle(self):
        output = ''
        with open(self._sql_file, 'r') as f:
            output = self._database.execute_sql_with_result(f.read())

        with open(self._out_file, 'w') as f:
            f.write(output)

    def _create_puzzle_input_table(self):
        self._database.execute_sql(
            f"CREATE TABLE {self._table_name} (value text)")

    def _insert_puzzle_input(self, rows: list[str]):
        values = ', '.join([f"('{row}')" for row in rows])
        self._database.execute_sql(
            f"INSERT INTO {self._table_name} (value) VALUES {values}")


if __name__ == '__main__':
    config = dotenv_values(".env")

    db = Database(
        username=config.get('USERNAME'),
        password=config.get('PASSWORD'),
        database_name=config.get('DATABASE_NAME'),
        host=config.get('HOST'),
    )
    db.create_database()

    files = glob.glob('assignments/*.sql')
    files = os_sorted(files)

    for file in files:
        stem = Path(file).stem
        print(f'Assignment {stem}')

        assignment = Assignment(stem, db)
        assignment.load_puzzle_input()
        assignment.execute_puzzle()
