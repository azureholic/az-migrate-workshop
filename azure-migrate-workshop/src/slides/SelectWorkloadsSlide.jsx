import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './SelectWorkloadsSlide.module.css'

export default function SelectWorkloadsSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.selectWorkloads}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 15</p>
          <h2>Select <span className={styles.highlight}>Workloads</span></h2>
          <p className={styles.subtitle}>
            Choose which discovered workloads to include in the business case
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>Select the workloads you want to include in the business case.</p>
              <p><strong>Do not select the az-migrate appliance</strong> — it was discovered as well, but we are not migrating it.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/WorkloadsForBusinessCase.png"
              alt="Select workloads for business case"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
