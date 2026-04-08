import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './ExecuteWaveSlide.module.css'

export default function ExecuteWaveSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.executeWave}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 27</p>
          <h2>Execute <span className={styles.highlight}>Wave</span></h2>
          <p className={styles.subtitle}>
            Run the migration for the Ubuntu VM
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>Return to the wave planning and <strong>execute the wave</strong> in the timeline.</p>
              <p>Review and execute the <strong>HyperV Servers to Azure VM</strong>.</p>
              <p>Hit <strong>Execute Migration</strong> for the Ubuntu VM.</p>
              <p>Review the target settings — choose <strong>vnet-migration-target</strong> as the network to deploy to. You can select the existing storage account or let the tool create one.</p>
              <p>Click through the migration wizard until you can hit <strong>Execute Migration</strong>.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/ExecuteWave.png"
              alt="Execute Wave"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
