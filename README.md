# create-beater-index

[beater][bouzuya/beater] index generator

## Usage

```bash
cd test/
npx create-beater-index
# or npm init beater-index
```

```bash
npx create-beater-index --help
# or npm init beater-index --help
```

## Example

```bash
$ cd test/
$ ls
foo.ts
$ cat foo.ts
import assert from 'assert';
import { test } from 'beater';

const tests = [
  test('example', () => {
    assert(1 === 1);
  })
];

export { tests };

$ npx create-beater-index
$ ls
foo.ts   index.ts
$ cat index.ts
import { Test } from 'beater';
import { tests as fooTests } from './foo';

const tests = ([] as Test[])
  .concat(fooTests);

export { tests };
```

## How to build

```bash
npm install
```

## License

[MIT](LICENSE)

## Author

[bouzuya][user] &lt;[m@bouzuya.net][email]&gt; ([https://bouzuya.net/][url])

[user]: https://github.com/bouzuya
[email]: mailto:m@bouzuya.net
[url]: https://bouzuya.net/

[bouzuya/beater]: https://github.com/bouzuya/beater
