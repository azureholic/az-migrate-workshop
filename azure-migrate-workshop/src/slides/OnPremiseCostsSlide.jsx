import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './OnPremiseCostsSlide.module.css'

export default function OnPremiseCostsSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.onPremiseCosts}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 12</p>
          <h2>On-Premise <span className={styles.highlight}>Costs</span></h2>
          <p className={styles.subtitle}>
            Review and adjust the on-premise cost assumptions in the migrate project
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>The on-premise costs are <strong>prefilled</strong> with default values, but can be edited to match your own environment and preferences.</p>
              <p>The business case generator will use these numbers to <strong>calculate costs and savings</strong> when comparing on-premise vs. Azure.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/BusinessCase-OnPremiseCosts.png"
              alt="Azure Migrate — On-Premise Costs configuration"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
