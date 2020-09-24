const fs = require('fs');
const nunjucks = require('nunjucks');
const path = require('path');
const spawn = require('child_process').spawnSync;

const package_config = require(path.join(process.env.INIT_CWD, 'package.json'));

nunjucks.configure({ autoescape: true });

(async () => {
  try {
    const template_dir = path.join(process.env.INIT_CWD, 'meta');
    const files = await fs.promises.readdir(template_dir);

    for (const file of files) {
      const file_path = path.join(template_dir, file);
      const out_filename = path.parse(file).name;

      await fs.promises.writeFile(
        path.join(process.env.INIT_CWD, out_filename),
        nunjucks.render (file_path, package_config),
        (err) => {
          if (err) {
            console.log(`error rendering ${file}: ${err}`);
          }
        }
      );
      await spawn('git', ['add', out_filename], { stdio: 'inherit' });
    }
  } catch(err) {
    console.log(err);
  }
})();
