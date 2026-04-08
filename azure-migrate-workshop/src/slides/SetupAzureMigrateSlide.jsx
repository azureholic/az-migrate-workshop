import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './SetupAzureMigrateSlide.module.css'

export default function SetupAzureMigrateSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.setupAzureMigrate}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 24</p>
          <h2>Setup <span className={styles.highlight}>Azure Migrate</span></h2>
          <p className={styles.subtitle}>
            Follow the wave guidance to set up the migration
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>Follow the wave guidance to perform all the steps needed to migrate.</p>
              <p>Start with <strong>Discover</strong>, select <strong>Azure VM</strong> as the target in the region your project is in.</p>
              <p>Click <strong>Create resources needed for the migration</strong>. Azure will take care of this.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/SetupAzureMigrate.png"
              alt="Setup Azure Migrate"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
