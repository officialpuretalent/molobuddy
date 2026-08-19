import { buildControlApi } from '../bootstrap/build_control_api.js';
import { loadConfig } from '../bootstrap/config.js';

async function start(): Promise<void> {
  try {
    const config = loadConfig(process.env);
    const app = await buildControlApi(config);

    const shutDown = async (): Promise<void> => {
      await app.close();
    };

    process.once('SIGINT', () => {
      void shutDown();
    });
    process.once('SIGTERM', () => {
      void shutDown();
    });

    await app.listen({ host: config.host, port: config.port });
  } catch {
    process.stderr.write('Molo control API failed to start.\n');
    process.exitCode = 1;
  }
}

await start();
